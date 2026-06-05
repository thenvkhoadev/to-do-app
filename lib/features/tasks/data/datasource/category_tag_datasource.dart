import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';

class CategoryRemoteDataSource {
  CategoryRemoteDataSource(this._client);
  final SupabaseClient _client;

  Stream<List<CategoryModel>> watchCategories(String userId) {
    return _client
        .from('categories')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((rows) => rows.map(CategoryModel.fromJson).toList());
  }

  Future<CategoryModel> createCategory(CategoryModel category) async {
    final data = await _client
        .from('categories')
        .insert(category.toInsertJson())
        .select()
        .single();
    return CategoryModel.fromJson(data);
  }

  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }

  Future<List<CategoryModel>> seedDefaultCategories(String userId) async {
    final defaults = [
      {'user_id': userId, 'name': 'Work', 'color': '#8083FF', 'icon': 'work'},
      {'user_id': userId, 'name': 'Personal', 'color': '#7CFFB2', 'icon': 'person'},
      {'user_id': userId, 'name': 'Learning', 'color': '#FFD166', 'icon': 'school'},
      {'user_id': userId, 'name': 'Health', 'color': '#FF6B9D', 'icon': 'favorite'},
      {'user_id': userId, 'name': 'Finance', 'color': '#06D6A0', 'icon': 'account_balance'},
    ];
    final data = await _client
        .from('categories')
        .insert(defaults)
        .select();
    return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
  }
}

class TagRemoteDataSource {
  TagRemoteDataSource(this._client);
  final SupabaseClient _client;

  Stream<List<TagModel>> watchTags(String userId) {
    return _client
        .from('tags')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((rows) => rows.map(TagModel.fromJson).toList());
  }

  Future<TagModel> createTag(TagModel tag) async {
    final data = await _client
        .from('tags')
        .insert(tag.toInsertJson())
        .select()
        .single();
    return TagModel.fromJson(data);
  }

  Future<void> deleteTag(String id) async {
    await _client.from('tags').delete().eq('id', id);
  }

  Future<List<TagModel>> seedDefaultTags(String userId) async {
    final defaults = [
      {'user_id': userId, 'name': 'Strategy', 'color': '#8083FF'},
      {'user_id': userId, 'name': 'DeepWork', 'color': '#7CFFB2'},
      {'user_id': userId, 'name': 'Urgent', 'color': '#FF6B9D'},
      {'user_id': userId, 'name': 'Backend', 'color': '#FFD166'},
      {'user_id': userId, 'name': 'Frontend', 'color': '#06D6A0'},
    ];
    final data = await _client
        .from('tags')
        .insert(defaults)
        .select();
    return (data as List).map((e) => TagModel.fromJson(e)).toList();
  }

  Future<void> setTaskTags(String taskId, List<String> tagIds) async {
    await _client.from('task_tags').delete().eq('task_id', taskId);
    if (tagIds.isEmpty) return;
    await _client.from('task_tags').insert(
          tagIds.map((tid) => {'task_id': taskId, 'tag_id': tid}).toList(),
        );
  }

  Future<List<String>> getTaskTagIds(String taskId) async {
    final data = await _client
        .from('task_tags')
        .select('tag_id')
        .eq('task_id', taskId);
    return (data as List).map((e) => e['tag_id'].toString()).toList();
  }
}
