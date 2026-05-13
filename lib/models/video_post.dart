class VideoPost {
  final String id;
  final String videoUrl;
  final String thumbnailAsset;
  final String username;
  final String caption;
  final int likes;
  final int comments;
  final int shares;

  const VideoPost({
    required this.id,
    required this.videoUrl,
    required this.thumbnailAsset,
    required this.username,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.shares,
  });

  VideoPost copyWith({
    String? id,
    String? videoUrl,
    String? thumbnailAsset,
    String? username,
    String? caption,
    int? likes,
    int? comments,
    int? shares,
  }) {
    return VideoPost(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailAsset: thumbnailAsset ?? this.thumbnailAsset,
      username: username ?? this.username,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoPost && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
