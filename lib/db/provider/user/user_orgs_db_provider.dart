import 'dart:async';
import 'package:gsy_github_app_flutter/common/utils/code_utils.dart';

import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/db/sql_provider.dart';
import 'package:gsy_github_app_flutter/model/user_org.dart';
import 'package:sqflite/sqflite.dart';

/// 用户组织表
/// Created by guoshuyu
/// Date: 2018-08-07

class UserOrgsDbProvider extends BaseDbProvider {
  final String name = 'UserOrgs';

  final String columnId = "_id";
  final String columnUserName = "userName";
  final String columnData = "data";

  int? id;
  String? userName;
  String? data;

  UserOrgsDbProvider();

  Map<String, dynamic> toMap(String? userName, String data) {
    Map<String, dynamic> map = {columnUserName: userName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  UserOrgsDbProvider.fromMap(Map map) {
    id = map[columnId];
    userName = map[columnUserName];
    data = map[columnData];
  }

  @override
  tableSqlString() {
    return tableBaseString(name, columnId) +
        '''
        $columnUserName text not null,
        $columnData text not null)
      ''';
  }

  @override
  tableName() {
    return name;
  }

  Future _getProvider(Database db, String? userName) async {
    List<Map<String, dynamic>> maps = await db.query(name,
        columns: [columnId, columnUserName, columnData],
        where: "$columnUserName = ?",
        whereArgs: [userName]);
    if (maps.isNotEmpty) {
      UserOrgsDbProvider provider = UserOrgsDbProvider.fromMap(maps.first);
      return provider;
    }
    return null;
  }

  ///插入到数据库
  Future insert(String? userName, String dataMapString) async {
    Database db = await getDataBase();
    var provider = await _getProvider(db, userName);
    if (provider != null) {
      await db
          .delete(name, where: "$columnUserName = ?", whereArgs: [userName]);
    }
    return await db.insert(name, toMap(userName, dataMapString));
  }

  ///获取数据
  Future<List<UserOrg>?> geData(String? userName) async {
    Database db = await getDataBase();

    var provider = await _getProvider(db, userName);
    if (provider != null) {
      List<UserOrg> list = [];

      ///使用 compute 的 Isolate 优化 json decode
      List<dynamic> eventMap =
          await compute(CodeUtils.decodeListResult, provider.data as String?);

      if (eventMap.isNotEmpty) {
        for (var item in eventMap) {
          list.add(UserOrg.fromJson(item));
        }
      }
      return list;
    }
    return null;
  }
}
