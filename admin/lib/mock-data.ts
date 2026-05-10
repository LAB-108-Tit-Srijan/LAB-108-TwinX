export const mockStats = {
  totalStudents: 1284,
  activeToday: 347,
  doubtsToday: 892,
  lecturesUploaded: 64,
  totalStudentsChange: 12,
  activeTodayChange: -3,
  doubtsTodayChange: 24,
  lecturesUploadedChange: 8,
};

export const mockDoubtsOverTime = [
  { day: "Mon", doubts: 342 },
  { day: "Tue", doubts: 518 },
  { day: "Wed", doubts: 421 },
  { day: "Thu", doubts: 687 },
  { day: "Fri", doubts: 593 },
  { day: "Sat", doubts: 892 },
  { day: "Sun", doubts: 731 },
];

export const mockConfusedTopics = [
  { topic: "useCallback vs useMemo", count: 234 },
  { topic: "Event Loop", count: 189 },
  { topic: "BST Deletion", count: 167 },
  { topic: "Async/Await", count: 143 },
  { topic: "CSS Grid", count: 121 },
];

export const mockRecentDoubts = [
  {
    id: "d1",
    student: "Arjun Sharma",
    lecture: "React Hooks Deep Dive",
    doubt: "What is the difference between useCallback and useMemo?",
    time: "2 min ago",
    status: "answered",
  },
  {
    id: "d2",
    student: "Priya Patel",
    lecture: "Node.js Event Loop",
    doubt: "Event loop kaise kaam karta hai?",
    time: "5 min ago",
    status: "answered",
  },
  {
    id: "d3",
    student: "Rahul Verma",
    lecture: "BST Operations",
    doubt: "How does BST deletion work with two children?",
    time: "12 min ago",
    status: "answered",
  },
  {
    id: "d4",
    student: "Sneha Kumar",
    lecture: "CSS Grid & Flexbox",
    doubt: "What is the difference between grid and flex?",
    time: "18 min ago",
    status: "answered",
  },
  {
    id: "d5",
    student: "Amit Singh",
    lecture: "Python Decorators",
    doubt: "How do closures work in Python decorators?",
    time: "25 min ago",
    status: "pending",
  },
];

export const mockAtRiskStudents = [
  { id: "s1", name: "Vikas Gupta", lastActive: "4 days ago", behind: 3, avatar: "VG" },
  { id: "s2", name: "Meena Joshi", lastActive: "5 days ago", behind: 5, avatar: "MJ" },
  { id: "s3", name: "Rohit Das", lastActive: "7 days ago", behind: 8, avatar: "RD" },
];

export const mockCourses = [
  {
    id: "c1",
    name: "React.js Mastery",
    instructor: "Rahul Gupta",
    lectures: 24,
    students: 487,
    status: "active",
    category: "Frontend",
  },
  {
    id: "c2",
    name: "Node.js Backend",
    instructor: "Priya Singh",
    lectures: 18,
    students: 312,
    status: "active",
    category: "Backend",
  },
  {
    id: "c3",
    name: "DSA with Python",
    instructor: "Amit Kumar",
    lectures: 32,
    students: 623,
    status: "active",
    category: "DSA",
  },
  {
    id: "c4",
    name: "Frontend Development",
    instructor: "Neha Joshi",
    lectures: 20,
    students: 289,
    status: "draft",
    category: "Frontend",
  },
  {
    id: "c5",
    name: "System Design",
    instructor: "Vikram Mehta",
    lectures: 15,
    students: 198,
    status: "active",
    category: "System Design",
  },
  {
    id: "c6",
    name: "Python Advanced",
    instructor: "Ananya Roy",
    lectures: 22,
    students: 0,
    status: "draft",
    category: "Python",
  },
];

export const mockLectures = [
  {
    id: "l1",
    title: "React Hooks Deep Dive",
    course: "React.js Mastery",
    duration: "42:31",
    uploaded: "May 5, 2026",
    doubts: 234,
    views: 1842,
  },
  {
    id: "l2",
    title: "Node.js Event Loop Explained",
    course: "Node.js Backend",
    duration: "38:15",
    uploaded: "May 6, 2026",
    doubts: 189,
    views: 934,
  },
  {
    id: "l3",
    title: "Binary Search Tree Operations",
    course: "DSA with Python",
    duration: "55:02",
    uploaded: "May 7, 2026",
    doubts: 167,
    views: 2341,
  },
  {
    id: "l4",
    title: "CSS Grid & Flexbox Mastery",
    course: "Frontend Development",
    duration: "31:44",
    uploaded: "May 8, 2026",
    doubts: 121,
    views: 3120,
  },
  {
    id: "l5",
    title: "Python Decorators & Generators",
    course: "Python Advanced",
    duration: "44:18",
    uploaded: "May 9, 2026",
    doubts: 143,
    views: 1567,
  },
];

export const mockStudents = [
  {
    id: "s1",
    name: "Arjun Sharma",
    avatar: "AS",
    phone: "+91 98765 43210",
    course: "React.js Mastery",
    progress: 62,
    doubts: 128,
    lastActive: "Just now",
    status: "active",
  },
  {
    id: "s2",
    name: "Priya Patel",
    avatar: "PP",
    phone: "+91 87654 32109",
    course: "Node.js Backend",
    progress: 28,
    doubts: 47,
    lastActive: "1h ago",
    status: "active",
  },
  {
    id: "s3",
    name: "Rahul Verma",
    avatar: "RV",
    phone: "+91 76543 21098",
    course: "DSA with Python",
    progress: 75,
    doubts: 203,
    lastActive: "3h ago",
    status: "active",
  },
  {
    id: "s4",
    name: "Sneha Kumar",
    avatar: "SK",
    phone: "+91 65432 10987",
    course: "Frontend Development",
    progress: 91,
    doubts: 56,
    lastActive: "1d ago",
    status: "inactive",
  },
  {
    id: "s5",
    name: "Vikas Gupta",
    avatar: "VG",
    phone: "+91 54321 09876",
    course: "React.js Mastery",
    progress: 12,
    doubts: 8,
    lastActive: "4d ago",
    status: "at-risk",
  },
  {
    id: "s6",
    name: "Meena Joshi",
    avatar: "MJ",
    phone: "+91 43210 98765",
    course: "DSA with Python",
    progress: 5,
    doubts: 3,
    lastActive: "5d ago",
    status: "at-risk",
  },
];

export const mockDoubtAnalytics = {
  totalDoubts: 5847,
  avgResponseTime: "2.3s",
  hindiPercent: 38,
  resolvedPercent: 97,
};

export const mockConfusionHeatmap = [
  {
    lecture: "React Hooks Deep Dive",
    segments: [2, 5, 3, 8, 12, 18, 9, 15, 7, 4],
  },
  {
    lecture: "Node.js Event Loop",
    segments: [1, 3, 14, 21, 8, 6, 3, 2, 1, 1],
  },
  {
    lecture: "BST Operations",
    segments: [4, 6, 8, 11, 16, 9, 7, 5, 3, 2],
  },
  {
    lecture: "CSS Grid & Flexbox",
    segments: [2, 4, 3, 5, 7, 4, 3, 2, 1, 1],
  },
];

export const mockTopQuestions = [
  { question: "What is the difference between useCallback and useMemo?", count: 234, lecture: "React Hooks", topic: "React" },
  { question: "Event loop kaise kaam karta hai?", count: 189, lecture: "Node.js Event Loop", topic: "Node.js" },
  { question: "How does BST deletion work with two children?", count: 167, lecture: "BST Operations", topic: "DSA" },
  { question: "What is the difference between grid and flex?", count: 143, lecture: "CSS Grid", topic: "CSS" },
  { question: "How do closures work in Python decorators?", count: 121, lecture: "Python Decorators", topic: "Python" },
  { question: "What is async/await and how is it different from Promises?", count: 118, lecture: "Node.js Event Loop", topic: "JavaScript" },
  { question: "Inorder traversal kya hota hai?", count: 97, lecture: "BST Operations", topic: "DSA" },
  { question: "How does useEffect dependency array work?", count: 89, lecture: "React Hooks", topic: "React" },
  { question: "What is memoization?", count: 76, lecture: "React Hooks", topic: "React" },
  { question: "How do Python generators differ from normal functions?", count: 68, lecture: "Python Decorators", topic: "Python" },
];

export const mockDoubtsByTopic = [
  { topic: "React", value: 1842, color: "#6C63FF" },
  { topic: "Node.js", value: 934, color: "#00D4FF" },
  { topic: "DSA", value: 1234, color: "#8B5CF6" },
  { topic: "Python", value: 876, color: "#10B981" },
  { topic: "CSS", value: 543, color: "#F59E0B" },
  { topic: "System Design", value: 418, color: "#EF4444" },
];

export const mockDoubtsByHour = [
  { hour: "6AM", doubts: 12 },
  { hour: "8AM", doubts: 34 },
  { hour: "10AM", doubts: 87 },
  { hour: "12PM", doubts: 124 },
  { hour: "2PM", doubts: 98 },
  { hour: "4PM", doubts: 143 },
  { hour: "6PM", doubts: 201 },
  { hour: "8PM", doubts: 287 },
  { hour: "10PM", doubts: 342 },
  { hour: "12AM", doubts: 198 },
  { hour: "2AM", doubts: 67 },
  { hour: "4AM", doubts: 18 },
];
