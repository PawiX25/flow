import "package:flow/entity/budget.dart";
import "package:flow/entity/category.dart";
import "package:flow/objectbox.dart";
import "package:flow/objectbox/objectbox.g.dart";
import "package:uuid/uuid.dart";

class BudgetService {
  static BudgetService? _instance;

  factory BudgetService() => _instance ??= BudgetService._internal();

  BudgetService._internal() {
    // Constructor
  }

  Future<Budget?> getOne(int id) async {
    return ObjectBox().box<Budget>().getAsync(id);
  }

  Budget? getOneSync(int id) {
    return ObjectBox().box<Budget>().get(id);
  }

  Future<List<Budget>> getAll() async {
    return ObjectBox().box<Budget>().getAllAsync();
  }

  List<Budget> getAllSync() {
    return ObjectBox().box<Budget>().getAll();
  }

  List<String> getAllUuidsSync() {
    return getAllSync().map((budget) => budget.uuid).toList();
  }

  Future<Budget?> findOne(dynamic identifier) async {
    if (identifier is int) {
      return await getOne(identifier);
    }

    if (identifier case String uuid when Uuid.isValidUUID(fromString: uuid)) {
      final q = ObjectBox()
          .box<Budget>()
          .query(Budget_.uuid.equals(uuid))
          .build();

      final Budget? result = await q.findFirstAsync();

      q.close();
      return result;
    }

    if (identifier case String name) {
      final q = ObjectBox()
          .box<Budget>()
          .query(Budget_.name.equals(name, caseSensitive: false))
          .build();

      final Budget? result = await q.findFirstAsync();

      q.close();
      return result;
    }

    return null;
  }

  Budget? findOneSync(dynamic identifier) {
    if (identifier is int) {
      return getOneSync(identifier);
    }

    if (identifier case String uuid when Uuid.isValidUUID(fromString: uuid)) {
      final q = ObjectBox()
          .box<Budget>()
          .query(Budget_.uuid.equals(uuid))
          .build();

      final Budget? result = q.findFirst();

      q.close();
      return result;
    }

    if (identifier case String name) {
      final q = ObjectBox()
          .box<Budget>()
          .query(Budget_.name.equals(name, caseSensitive: false))
          .build();

      final Budget? result = q.findFirst();

      q.close();
      return result;
    }

    return null;
  }

  Future<int> upsertOne(Budget budget) async {
    return ObjectBox().box<Budget>().putAsync(budget);
  }

  int upsertOneSync(Budget budget) {
    return ObjectBox().box<Budget>().put(budget);
  }

  Future<int> upsertOneWithCategories(
    Budget budget,
    List<Category>? categories,
  ) async {
    budget.setCategories(categories);
    return upsertOne(budget);
  }

  int upsertOneWithCategoriesSync(
    Budget budget,
    List<Category>? categories,
  ) {
    budget.setCategories(categories);
    return upsertOneSync(budget);
  }

  /// Returns `true` if the budget existed and was deleted, `false` otherwise.
  Future<bool> deleteOne(dynamic identifier) async {
    final Budget? budget = await findOne(identifier);

    if (budget == null) {
      return false;
    }

    return ObjectBox().box<Budget>().remove(budget.id);
  }

  /// Returns `true` if the budget existed and was deleted, `false` otherwise.
  bool deleteOneSync(dynamic identifier) {
    final Budget? budget = findOneSync(identifier);

    if (budget == null) {
      return false;
    }

    return ObjectBox().box<Budget>().remove(budget.id);
  }
}
