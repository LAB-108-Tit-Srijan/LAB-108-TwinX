import '../models/student_model.dart';
import '../models/lecture_model.dart';
import '../models/doubt_model.dart';
import '../models/course_model.dart';

class MockData {
  static const StudentModel currentStudent = StudentModel(
    id: 's1',
    name: 'Arjun Sharma',
    phone: '+91 98765 43210',
    institute: 'IIT Delhi',
    avatarInitials: 'AS',
    streakDays: 14,
    lecturesWatched: 47,
    doubtsAsked: 128,
  );

  static const List<LectureModel> lectures = [
    LectureModel(
      id: 'l1',
      title: 'React Hooks Deep Dive',
      courseName: 'React.js Mastery',
      instructorName: 'Rahul Gupta',
      duration: '42 min',
      thumbnailGradient: 'indigo',
      progress: 0.65,
      doubtsCount: 23,
      level: 'Intermediate',
      views: 1842,
      description:
          'Master all React hooks including useState, useEffect, useCallback, useMemo, and custom hooks with real-world examples.',
      topics: ['useState', 'useEffect', 'useCallback', 'useMemo', 'Custom Hooks'],
    ),
    LectureModel(
      id: 'l2',
      title: 'Node.js Event Loop Explained',
      courseName: 'Node.js Backend',
      instructorName: 'Priya Singh',
      duration: '38 min',
      thumbnailGradient: 'cyan',
      progress: 0.30,
      doubtsCount: 18,
      isNew: true,
      level: 'Advanced',
      views: 934,
      description:
          'Deep dive into the Node.js event loop, call stack, callback queue, and how async operations are handled.',
      topics: ['Event Loop', 'Callback Queue', 'Promise', 'async/await'],
    ),
    LectureModel(
      id: 'l3',
      title: 'Binary Search Tree Operations',
      courseName: 'DSA with Python',
      instructorName: 'Amit Kumar',
      duration: '55 min',
      thumbnailGradient: 'purple',
      progress: 0.0,
      doubtsCount: 31,
      level: 'Beginner',
      views: 2341,
      description:
          'Understand BST insertion, deletion, traversal and balancing with visual animations.',
      topics: ['BST', 'Traversal', 'Inorder', 'Preorder', 'Postorder'],
    ),
    LectureModel(
      id: 'l4',
      title: 'CSS Grid & Flexbox Mastery',
      courseName: 'Frontend Development',
      instructorName: 'Neha Joshi',
      duration: '31 min',
      thumbnailGradient: 'pink',
      progress: 1.0,
      doubtsCount: 12,
      isNew: true,
      level: 'Beginner',
      views: 3120,
      description:
          'Complete guide to CSS Grid and Flexbox layouts with hands-on projects.',
      topics: ['Grid', 'Flexbox', 'Responsive Design', 'CSS Variables'],
    ),
    LectureModel(
      id: 'l5',
      title: 'Python Decorators & Generators',
      courseName: 'Python Advanced',
      instructorName: 'Vikram Mehta',
      duration: '44 min',
      thumbnailGradient: 'orange',
      progress: 0.50,
      doubtsCount: 19,
      level: 'Advanced',
      views: 1567,
      description:
          'Learn Python decorators, generators, and iterators with practical examples.',
      topics: ['Decorators', 'Generators', 'Yield', 'Iterators', 'Closures'],
    ),
  ];

  static final List<DoubtModel> doubts = [
    DoubtModel(
      id: 'd1',
      question: 'What is the difference between useCallback and useMemo?',
      answer:
          '**useCallback** returns a memoized callback function, while **useMemo** returns a memoized value.\n\nuseCallback prevents a function from being recreated on every render. useMemo caches the result of an expensive calculation.\n\n📍 From 42:31 — In this timestamp, Rahul explains this with a live counter example.',
      lectureId: 'l1',
      lectureName: 'React Hooks Deep Dive',
      timestamp: '42:31',
      askedAt: DateTime(2026, 5, 9, 21, 30),
      language: 'EN',
      isAi: false,
    ),
    DoubtModel(
      id: 'd1_ai',
      question: '',
      answer:
          '**useCallback** returns a memoized callback function, while **useMemo** returns a memoized value.\n\nuseCallback prevents a function from being recreated on every render. useMemo caches the result of an expensive calculation.\n\n📍 From 42:31 — In this timestamp, Rahul explains this with a live counter example.',
      lectureId: 'l1',
      lectureName: 'React Hooks Deep Dive',
      timestamp: '42:31',
      askedAt: DateTime(2026, 5, 9, 21, 30),
      language: 'EN',
      isAi: true,
    ),
    DoubtModel(
      id: 'd2',
      question: 'Event loop kaise kaam karta hai Node.js mein?',
      answer:
          '**Event Loop** Node.js ka core mechanism hai jo asynchronous operations handle karta hai.\n\n1. Call Stack — Synchronous code execute hota hai\n2. Web APIs — setTimeout, fetch async operations yahan jaate hain\n3. Callback Queue — Completed callbacks yahan wait karte hain\n4. Event Loop — Jab stack khali ho, callbacks ko push karta hai\n\n📍 From 12:45 — Is timestamp par diagram ke saath samjhaya gaya hai.',
      lectureId: 'l2',
      lectureName: 'Node.js Event Loop',
      timestamp: '12:45',
      askedAt: DateTime(2026, 5, 9, 17, 0),
      language: 'HI',
      isAi: false,
    ),
    DoubtModel(
      id: 'd3',
      question: 'How does BST deletion work when node has two children?',
      answer:
          'When deleting a node with two children from a BST:\n\n1. Find the inorder successor (smallest node in right subtree)\n2. Copy its value to the node being deleted\n3. Delete the inorder successor from the right subtree\n\n📍 From 28:15 — Visual animation of this process is shown here.\n🔗 Also in Lecture 2 · 15:42 — Similar concept covered for AVL trees.',
      lectureId: 'l3',
      lectureName: 'Binary Search Tree Operations',
      timestamp: '28:15',
      askedAt: DateTime(2026, 5, 8, 22, 0),
      language: 'EN',
      isAi: false,
    ),
  ];

  static const List<CourseModel> courses = [
    CourseModel(
      id: 'c1',
      name: 'React.js Mastery',
      instructor: 'Rahul Gupta',
      totalLectures: 24,
      completedLectures: 15,
      category: 'Frontend',
      progress: 0.625,
    ),
    CourseModel(
      id: 'c2',
      name: 'Node.js Backend',
      instructor: 'Priya Singh',
      totalLectures: 18,
      completedLectures: 5,
      category: 'Backend',
      progress: 0.278,
    ),
    CourseModel(
      id: 'c3',
      name: 'DSA with Python',
      instructor: 'Amit Kumar',
      totalLectures: 32,
      completedLectures: 12,
      category: 'DSA',
      progress: 0.375,
    ),
  ];

  static const List<String> filterTopics = [
    'All', 'React', 'Node.js', 'DSA', 'Python', 'System Design', 'Databases',
  ];

  static const List<Map<String, dynamic>> weeklyActivity = [
    {'day': 'Mon', 'doubts': 5},
    {'day': 'Tue', 'doubts': 8},
    {'day': 'Wed', 'doubts': 3},
    {'day': 'Thu', 'doubts': 12},
    {'day': 'Fri', 'doubts': 7},
    {'day': 'Sat', 'doubts': 15},
    {'day': 'Sun', 'doubts': 9},
  ];

  static const List<String> masteredConcepts = [
    'useState', 'useEffect', 'Props', 'JSX', 'Components',
    'Flexbox', 'Grid', 'CSS Variables', 'Responsive',
    'Arrays', 'Linked Lists', 'Recursion', 'Sorting',
    'Closures', 'Promises', 'async/await',
  ];

  static const List<String> studyingTopics = [
    'React', 'Node.js', 'DSA', 'Python', 'System Design',
  ];
}
