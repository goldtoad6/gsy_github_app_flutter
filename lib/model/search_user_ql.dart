class SearchUserQL({
  final int? followers,
  final String? name,
  final String? avatarUrl,
  final String? bio,
  final String? login,
  final String? lang,
  final bool isOrganization = false,
}) {
  static SearchUserQL fromMap(Map? map) {
    if (map == null) {
      return SearchUserQL();
    }
    String? lang;
    final langNode = map['lang'];
    if (langNode is Map) {
      final nodes = langNode['nodes'];
      if (nodes is List && nodes.isNotEmpty && nodes.first is Map) {
        final languages = (nodes.first as Map)['languages'];
        if (languages is Map) {
          final langNodes = languages['nodes'];
          if (langNodes is List &&
              langNodes.isNotEmpty &&
              langNodes.first is Map) {
            lang = (langNodes.first as Map)['name'] as String?;
          }
        }
      }
    }

    // GitHub `search(type: USER)` 的 union 里 Organization 命中时字段不同：
    // - `bio` 在 User 上；Organization 用 `description`
    // - `followers` 在 User 上（totalCount）；Organization 无 followers 概念，
    //   我们用 `membersWithRole.totalCount` 近似"关注度"以便 UI 沿用 followers 数字位
    // 详见 [users.dart] 的 readTrendUser query 头注释。
    final isOrg = map['__typename'] == 'Organization';

    int? followers;
    final followersNode = isOrg ? map['membersWithRole'] : map['followers'];
    if (followersNode is Map) {
      followers = (followersNode['totalCount'] as num?)?.toInt();
    }

    final String? bio =
        (isOrg ? map['description'] : map['bio']) as String?;

    return SearchUserQL(
      followers: followers,
      name: map['name'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      bio: bio,
      login: map['login'] as String?,
      lang: lang,
      isOrganization: isOrg,
    );
  }
}
