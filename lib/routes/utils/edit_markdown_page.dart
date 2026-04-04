import "package:flow/l10n/flow_localizations.dart";
import "package:flow/theme/helpers.dart";
import "package:flow/widgets/general/form_close_button.dart";
import "package:flow/widgets/general/frame.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:material_symbols_icons/symbols.dart";
import "package:super_editor/super_editor.dart";

class EditMarkdownPageProps {
  final String? initialValue;
  final int? maxLength;

  const EditMarkdownPageProps({this.initialValue, this.maxLength});
}

class EditMarkdownPage extends StatefulWidget {
  final String? initialValue;
  final int? maxLength;

  const EditMarkdownPage({super.key, this.initialValue, this.maxLength});
  EditMarkdownPage.fromProps({super.key, required EditMarkdownPageProps props})
    : initialValue = props.initialValue,
      maxLength = props.maxLength;

  @override
  State<EditMarkdownPage> createState() => _EditMarkdownPageState();
}

class _EditMarkdownPageState extends State<EditMarkdownPage> {
  late final MutableDocument _document;
  late final MutableDocumentComposer _composer;
  late final Editor _editor;

  late final String _initialMarkdown;

  final FocusNode _editorFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    final bool hasInitialValue =
        widget.initialValue != null && widget.initialValue!.trim().isNotEmpty;

    _document = hasInitialValue
        ? deserializeMarkdownToDocument(
            widget.initialValue!,
            syntax: MarkdownSyntax.normal,
            encodeHtml: false,
          )
        : MutableDocument(
            nodes: [
              ParagraphNode(
                id: Editor.createNodeId(),
                text: AttributedText(),
              ),
            ],
          );

    _composer = MutableDocumentComposer();
    _editor = createDefaultDocumentEditor(
      document: _document,
      composer: _composer,
    );

    _initialMarkdown = serializeDocumentToMarkdown(
      _document,
      syntax: MarkdownSyntax.normal,
    ).trim();
  }

  @override
  void dispose() {
    _editorFocusNode.dispose();
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 40.0,
          leading: FormCloseButton(canPop: () => !hasChanged()),
          actions: [
            IconButton(
              onPressed: save,
              icon: const Icon(Symbols.check_rounded),
              tooltip: "general.save".t(context),
            ),
          ],
          centerTitle: true,
          backgroundColor: context.colorScheme.surface,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _EditorToolbar(
                editor: _editor,
                document: _document,
                composer: _composer,
              ),
              Expanded(
                child: Frame.standalone(
                  child: SuperEditor(
                    focusNode: _editorFocusNode,
                    editor: _editor,
                    stylesheet: defaultStylesheet.copyWith(
                      documentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 0,
                      ),
                    ),
                    componentBuilders: [
                      TaskComponentBuilder(_editor),
                      ...defaultComponentBuilders,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> save() async {
    final markdown = serializeDocumentToMarkdown(
      _document,
      syntax: MarkdownSyntax.normal,
    );
    context.pop<String>(markdown);
  }

  bool hasChanged() {
    try {
      final String currentMarkdown = serializeDocumentToMarkdown(
        _document,
        syntax: MarkdownSyntax.normal,
      ).trim();

      return currentMarkdown != _initialMarkdown;
    } catch (e) {
      return false;
    }
  }
}

class _EditorToolbar extends StatefulWidget {
  final Editor editor;
  final MutableDocument document;
  final MutableDocumentComposer composer;

  const _EditorToolbar({
    required this.editor,
    required this.document,
    required this.composer,
  });

  @override
  State<_EditorToolbar> createState() => _EditorToolbarState();
}

class _EditorToolbarState extends State<_EditorToolbar> {
  @override
  void initState() {
    super.initState();
    widget.composer.selectionNotifier.addListener(_onSelectionChange);
  }

  @override
  void dispose() {
    widget.composer.selectionNotifier.removeListener(_onSelectionChange);
    super.dispose();
  }

  void _onSelectionChange() {
    setState(() {});
  }

  bool _doesSelectionHaveAttribution(Attribution attribution) {
    final selection = widget.composer.selection;
    if (selection == null) return false;

    if (selection.isCollapsed) {
      return widget.composer.preferences.currentAttributions
          .contains(attribution);
    }

    return widget.document.doesSelectedTextContainAttributions(
      selection,
      {attribution},
    );
  }

  void _toggleAttribution(Attribution attribution) {
    final selection = widget.composer.selection;
    if (selection == null) return;

    if (selection.isCollapsed) {
      widget.composer.preferences.toggleStyle(attribution);
    } else {
      widget.editor.execute([
        ToggleTextAttributionsRequest(
          documentRange: selection,
          attributions: {attribution},
        ),
      ]);
    }

    setState(() {});
  }

  Attribution? _getCurrentBlockType() {
    final selection = widget.composer.selection;
    if (selection == null) return null;

    final node = widget.document.getNodeById(selection.extent.nodeId);
    if (node is ParagraphNode) {
      return node.getMetadataValue("blockType");
    }
    return null;
  }

  bool _isListItem([ListItemType? type]) {
    final selection = widget.composer.selection;
    if (selection == null) return false;

    final node = widget.document.getNodeById(selection.extent.nodeId);
    if (node is ListItemNode) {
      return type == null || node.type == type;
    }
    return false;
  }

  bool _isTask() {
    final selection = widget.composer.selection;
    if (selection == null) return false;

    return widget.document.getNodeById(selection.extent.nodeId) is TaskNode;
  }

  void _convertToHeader(Attribution headerAttribution) {
    final selection = widget.composer.selection;
    if (selection == null) return;

    final node = widget.document.getNodeById(selection.extent.nodeId);
    if (node is! TextNode) return;

    if (node is ListItemNode) {
      widget.editor.execute([
        ConvertListItemToParagraphRequest(
          nodeId: node.id,
          paragraphMetadata: {"blockType": headerAttribution},
        ),
      ]);
    } else if (node is TaskNode) {
      widget.editor.execute([
        ConvertTaskToParagraphRequest(
          nodeId: node.id,
          paragraphMetadata: {"blockType": headerAttribution},
        ),
      ]);
    } else {
      final currentBlockType = _getCurrentBlockType();
      widget.editor.execute([
        ChangeParagraphBlockTypeRequest(
          nodeId: node.id,
          blockType: currentBlockType == headerAttribution
              ? paragraphAttribution
              : headerAttribution,
        ),
      ]);
    }
    setState(() {});
  }

  void _convertToListItem(ListItemType type) {
    final selection = widget.composer.selection;
    if (selection == null) return;

    final node = widget.document.getNodeById(selection.extent.nodeId);
    if (node is! TextNode) return;

    if (_isListItem(type)) {
      widget.editor.execute([
        ConvertListItemToParagraphRequest(nodeId: node.id),
      ]);
    } else if (node is ListItemNode) {
      widget.editor.execute([
        ChangeListItemTypeRequest(nodeId: node.id, newType: type),
      ]);
    } else if (node is TaskNode) {
      widget.editor.execute([
        ConvertTaskToParagraphRequest(nodeId: node.id),
      ]);
      widget.editor.execute([
        ConvertParagraphToListItemRequest(nodeId: node.id, type: type),
      ]);
    } else {
      widget.editor.execute([
        ConvertParagraphToListItemRequest(nodeId: node.id, type: type),
      ]);
    }
    setState(() {});
  }

  void _convertToTask() {
    final selection = widget.composer.selection;
    if (selection == null) return;

    final node = widget.document.getNodeById(selection.extent.nodeId);
    if (node is! TextNode) return;

    if (_isTask()) {
      widget.editor.execute([
        ConvertTaskToParagraphRequest(nodeId: node.id),
      ]);
    } else if (node is ListItemNode) {
      widget.editor.execute([
        ConvertListItemToParagraphRequest(nodeId: node.id),
      ]);
      widget.editor.execute([
        ConvertParagraphToTaskRequest(nodeId: node.id),
      ]);
    } else {
      widget.editor.execute([
        ConvertParagraphToTaskRequest(nodeId: node.id),
      ]);
    }
    setState(() {});
  }

  void _convertToBlockquote() {
    final selection = widget.composer.selection;
    if (selection == null) return;

    final node = widget.document.getNodeById(selection.extent.nodeId);
    if (node is! TextNode) return;

    final currentBlockType = _getCurrentBlockType();

    if (node is ListItemNode) {
      widget.editor.execute([
        ConvertListItemToParagraphRequest(
          nodeId: node.id,
          paragraphMetadata: {"blockType": blockquoteAttribution},
        ),
      ]);
    } else if (node is TaskNode) {
      widget.editor.execute([
        ConvertTaskToParagraphRequest(
          nodeId: node.id,
          paragraphMetadata: {"blockType": blockquoteAttribution},
        ),
      ]);
    } else {
      widget.editor.execute([
        ChangeParagraphBlockTypeRequest(
          nodeId: node.id,
          blockType: currentBlockType == blockquoteAttribution
              ? paragraphAttribution
              : blockquoteAttribution,
        ),
      ]);
    }
    setState(() {});
  }

  void _convertToCodeBlock() {
    final selection = widget.composer.selection;
    if (selection == null) return;

    final node = widget.document.getNodeById(selection.extent.nodeId);
    if (node is! TextNode) return;

    final currentBlockType = _getCurrentBlockType();

    if (node is ListItemNode) {
      widget.editor.execute([
        ConvertListItemToParagraphRequest(
          nodeId: node.id,
          paragraphMetadata: {"blockType": codeAttribution},
        ),
      ]);
    } else if (node is TaskNode) {
      widget.editor.execute([
        ConvertTaskToParagraphRequest(
          nodeId: node.id,
          paragraphMetadata: {"blockType": codeAttribution},
        ),
      ]);
    } else {
      widget.editor.execute([
        ChangeParagraphBlockTypeRequest(
          nodeId: node.id,
          blockType: currentBlockType == codeAttribution
              ? paragraphAttribution
              : codeAttribution,
        ),
      ]);
    }
    setState(() {});
  }

  void _insertHorizontalRule() {
    final selection = widget.composer.selection;
    if (selection == null) return;

    final node = widget.document.getNodeById(selection.extent.nodeId);
    if (node == null) return;

    final newNodeId = Editor.createNodeId();
    final afterRuleNodeId = Editor.createNodeId();

    widget.editor.execute([
      InsertNodeAfterNodeRequest(
        existingNodeId: node.id,
        newNode: HorizontalRuleNode(id: newNodeId),
      ),
      InsertNodeAfterNodeRequest(
        existingNodeId: newNodeId,
        newNode: ParagraphNode(
          id: afterRuleNodeId,
          text: AttributedText(),
        ),
      ),
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: afterRuleNodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.insertContent,
        SelectionReason.userInteraction,
      ),
    ]);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final blockType = _getCurrentBlockType();
    final isBold = _doesSelectionHaveAttribution(boldAttribution);
    final isItalic = _doesSelectionHaveAttribution(italicsAttribution);
    final isUnderline = _doesSelectionHaveAttribution(underlineAttribution);
    final isStrikethrough = _doesSelectionHaveAttribution(
      strikethroughAttribution,
    );
    final isCode = _doesSelectionHaveAttribution(codeAttribution);

    return Material(
      elevation: 1.0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          child: Row(
            children: [
              // Undo / Redo
              IconButton(
                icon: const Icon(Symbols.undo_rounded),
                iconSize: 20.0,
                onPressed: () => widget.editor.undo(),
                tooltip: "Undo",
              ),
              IconButton(
                icon: const Icon(Symbols.redo_rounded),
                iconSize: 20.0,
                onPressed: () => widget.editor.redo(),
                tooltip: "Redo",
              ),
              _divider(),

              // Inline styles
              _toolbarButton(
                icon: Symbols.format_bold_rounded,
                isActive: isBold,
                onPressed: () => _toggleAttribution(boldAttribution),
                tooltip: "Bold",
              ),
              _toolbarButton(
                icon: Symbols.format_italic_rounded,
                isActive: isItalic,
                onPressed: () => _toggleAttribution(italicsAttribution),
                tooltip: "Italic",
              ),
              _toolbarButton(
                icon: Symbols.format_underlined_rounded,
                isActive: isUnderline,
                onPressed: () => _toggleAttribution(underlineAttribution),
                tooltip: "Underline",
              ),
              _toolbarButton(
                icon: Symbols.strikethrough_s_rounded,
                isActive: isStrikethrough,
                onPressed: () => _toggleAttribution(strikethroughAttribution),
                tooltip: "Strikethrough",
              ),
              _toolbarButton(
                icon: Symbols.code_rounded,
                isActive: isCode,
                onPressed: () => _toggleAttribution(codeAttribution),
                tooltip: "Inline Code",
              ),
              _divider(),

              // Block types
              _toolbarButton(
                icon: Symbols.title_rounded,
                isActive: blockType == header1Attribution,
                onPressed: () => _convertToHeader(header1Attribution),
                tooltip: "Header 1",
              ),
              _toolbarButton(
                icon: Symbols.text_fields_rounded,
                isActive: blockType == header2Attribution,
                onPressed: () => _convertToHeader(header2Attribution),
                tooltip: "Header 2",
              ),
              _toolbarButton(
                icon: Symbols.text_fields_rounded,
                iconSize: 16.0,
                isActive: blockType == header3Attribution,
                onPressed: () => _convertToHeader(header3Attribution),
                tooltip: "Header 3",
              ),
              _divider(),

              // Lists
              _toolbarButton(
                icon: Symbols.format_list_bulleted_rounded,
                isActive: _isListItem(ListItemType.unordered),
                onPressed: () => _convertToListItem(ListItemType.unordered),
                tooltip: "Bullet List",
              ),
              _toolbarButton(
                icon: Symbols.format_list_numbered_rounded,
                isActive: _isListItem(ListItemType.ordered),
                onPressed: () => _convertToListItem(ListItemType.ordered),
                tooltip: "Numbered List",
              ),
              _toolbarButton(
                icon: Symbols.checklist_rounded,
                isActive: _isTask(),
                onPressed: _convertToTask,
                tooltip: "Task List",
              ),
              _divider(),

              // Block elements
              _toolbarButton(
                icon: Symbols.format_quote_rounded,
                isActive: blockType == blockquoteAttribution,
                onPressed: _convertToBlockquote,
                tooltip: "Blockquote",
              ),
              _toolbarButton(
                icon: Symbols.code_blocks_rounded,
                isActive: blockType == codeAttribution,
                onPressed: _convertToCodeBlock,
                tooltip: "Code Block",
              ),
              IconButton(
                icon: const Icon(Symbols.horizontal_rule_rounded),
                iconSize: 20.0,
                onPressed: _insertHorizontalRule,
                tooltip: "Horizontal Rule",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    String? tooltip,
    double iconSize = 20.0,
  }) {
    return IconButton(
      icon: Icon(icon, size: iconSize),
      isSelected: isActive,
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: isActive
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
    );
  }

  Widget _divider() {
    return SizedBox(
      height: 24.0,
      child: VerticalDivider(width: 8.0),
    );
  }
}
