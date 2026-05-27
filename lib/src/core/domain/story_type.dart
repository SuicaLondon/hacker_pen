enum StoryType { top, newStories, best, ask, show, job }

extension StoryTypeMetadata on StoryType {
  static const List<StoryType> homeTabs = <StoryType>[
    StoryType.top,
    StoryType.newStories,
    StoryType.best,
    StoryType.ask,
    StoryType.show,
    StoryType.job,
  ];

  String get label {
    switch (this) {
      case StoryType.top:
        return 'Top';
      case StoryType.newStories:
        return 'New';
      case StoryType.best:
        return 'Best';
      case StoryType.ask:
        return 'Ask';
      case StoryType.show:
        return 'Show';
      case StoryType.job:
        return 'Jobs';
    }
  }

  String get endpointPath {
    switch (this) {
      case StoryType.top:
        return '/topstories.json';
      case StoryType.newStories:
        return '/newstories.json';
      case StoryType.best:
        return '/beststories.json';
      case StoryType.ask:
        return '/askstories.json';
      case StoryType.show:
        return '/showstories.json';
      case StoryType.job:
        return '/jobstories.json';
    }
  }
}
