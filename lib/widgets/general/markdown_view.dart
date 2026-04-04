import "package:flow/widgets/general/frame.dart";
import "package:flutter/material.dart";
import "package:super_editor/super_editor.dart";

class MarkdownView extends StatefulWidget {
  final String? markdown;
  final FocusNode? focusNode;

  final Function(String)? onChanged;

  const MarkdownView({
    super.key,
    required this.markdown,
    this.focusNode,
    this.onChanged,
  });

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  late final MutableDocument _document;
  late final MutableDocumentComposer _composer;
  late final Editor _editor;

  @override
  void initState() {
    super.initState();

    final bool hasContent =
        widget.markdown != null && widget.markdown!.trim().isNotEmpty;

    _document = hasContent
        ? deserializeMarkdownToDocument(
            widget.markdown!,
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
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Frame(
        child: SuperReader(
          editor: _editor,
          shrinkWrap: true,
        ),
      ),
    );
  }
}
