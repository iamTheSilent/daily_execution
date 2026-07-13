import 'package:flutter/material.dart';
import '../date/app_date.dart';

class AppStrings {
  const AppStrings(this.locale);
  final Locale locale;

  bool get _fa => locale.languageCode == 'fa';

  // ── اپ ────────────────────────────────────────────────────────────────────
  String get appTitle => _fa ? 'اجرای روزانه' : 'Daily Execution';

  // ── نوار پایین ────────────────────────────────────────────────────────────
  String get navToday    => _fa ? 'امروز'     : 'Today';
  String get navInbox    => _fa ? 'صندوق'    : 'Inbox';
  String get navPlans    => _fa ? 'برنامه‌ها' : 'Plans';
  String get navCalendar => _fa ? 'تقویم'    : 'Calendar';
  String get navSettings => _fa ? 'تنظیمات'  : 'Settings';

  // ── صفحهٔ برنامه‌ها و ایده‌ها ─────────────────────────────────────────────
  String get plansScreenTitle => _fa ? 'ایده‌ها و برنامه‌ها' : 'Plans & Ideas';
  String get tabPlans         => _fa ? 'برنامه‌ها'            : 'Plans';
  String get tabIdeas         => _fa ? 'ایده‌ها'              : 'Ideas';
  String get newPlanHint      => _fa ? 'نام برنامه…'         : 'Plan name…';
  String get newIdeaHint      => _fa ? 'ایده‌ات رو بنویس…'   : 'Write your idea…';
  String get emptyPlans       => _fa ? 'برنامه‌ای نداری\nبا + یکی بساز'   : 'No plans yet\nTap + to create one';
  String get emptyIdeas       => _fa ? 'ایده‌ای ثبت نشده\nبا + بنویس'     : 'No ideas yet\nTap + to capture one';
  String get convertToPlan    => _fa ? 'تبدیل به برنامه'      : 'Convert to plan';
  String get sendToToday      => _fa ? 'ارسال به امروز'        : 'Send to Today';
  String get convertedMsg     => _fa ? 'به برنامه‌ها اضافه شد ✓' : 'Added to plans ✓';
  String get sentToTodayMsg   => _fa ? 'به امروز اضافه شد ✓'    : 'Added to today ✓';

  // ── جمع‌وجورِ برنامه‌ها (سنجاق / بایگانی / عقب‌افتاده) ──────────────────────
  String get overdueLabel     => _fa ? 'عقب‌افتاده'          : 'Overdue';
  String get pinLabel         => _fa ? 'سنجاق کردن'          : 'Pin';
  String get unpinLabel       => _fa ? 'برداشتنِ سنجاق'      : 'Unpin';
  String get archiveLabel     => _fa ? 'بایگانی'             : 'Archive';
  String get unarchiveLabel   => _fa ? 'خروج از بایگانی'     : 'Unarchive';
  String get archivedSection  => _fa ? 'بایگانی‌شده‌ها'       : 'Archived';
  String get archivedMsg      => _fa ? 'بایگانی شد ✓'         : 'Archived ✓';
  String get unarchivedMsg    => _fa ? 'از بایگانی خارج شد ✓' : 'Unarchived ✓';
  String number(int n)        => _fa ? toFaDigits('$n') : '$n';

  // ── پوشه‌های ایده ─────────────────────────────────────────────────────────
  String get newFolder        => _fa ? 'پوشهٔ جدید'        : 'New folder';
  String get folderNameHint   => _fa ? 'نام پوشه…'         : 'Folder name…';
  String get editFolder       => _fa ? 'ویرایش پوشه'       : 'Edit folder';
  String get emptyFolders     => _fa ? 'هنوز پوشه‌ای نداری\nبا + یکی بساز' : 'No folders yet\nTap + to create one';
  String get uncategorized    => _fa ? 'بدونِ پوشه'        : 'No folder';
  String get emptyFolderIdeas => _fa ? 'این پوشه خالی است\nبا + ایده اضافه کن' : 'This folder is empty\nTap + to add an idea';
  String ideaCount(int n)     => _fa ? '${toFaDigits('$n')} ایده' : '$n ideas';

  // ── اکشن‌های ایده ─────────────────────────────────────────────────────────
  String get convertToTask    => _fa ? 'تبدیل به کار'        : 'Convert to Task';
  String get scheduleToDay    => _fa ? 'زمان‌بندی برای روز…' : 'Schedule to Day…';
  String get addToPlan        => _fa ? 'افزودن به برنامه…'   : 'Add to Plan…';
  String get moveToFolder     => _fa ? 'انتقال به پوشه…'     : 'Move to Folder…';
  String get pickPlan         => _fa ? 'یک برنامه انتخاب کن' : 'Pick a plan';
  String get pickFolder       => _fa ? 'یک پوشه انتخاب کن'   : 'Pick a folder';
  String get noPlansToPick    => _fa ? 'هیچ برنامه‌ای نداری' : 'No plans yet';
  String get scheduledMsg     => _fa ? 'زمان‌بندی شد ✓'      : 'Scheduled ✓';
  String get addedToPlanMsg   => _fa ? 'به برنامه اضافه شد ✓' : 'Added to plan ✓';
  String get movedMsg         => _fa ? 'منتقل شد ✓'          : 'Moved ✓';

  // ── حذف پوشه ──────────────────────────────────────────────────────────────
  String get deleteFolderQ    => _fa ? 'حذف پوشه؟'           : 'Delete folder?';
  String get deleteFolderMsg  => _fa ? 'ایده‌های داخلِ این پوشه هم حذف شوند؟' : 'Delete the ideas inside too?';
  String get deleteAllLabel   => _fa ? 'بله، همه حذف شوند'   : 'Yes, delete all';
  String get keepIdeasLabel   => _fa ? 'نه، نگه‌دار'         : 'No, keep them';

  // ── صفحهٔ جزئیاتِ برنامه ───────────────────────────────────────────────────
  String get remainingLabel  => _fa ? 'باقی‌مانده'  : 'remaining';
  String get doneLabel       => _fa ? 'انجام‌شده'   : 'done';
  String get emptyPlanTasks  => _fa ? 'هنوز کاری توی این برنامه نیست\nبا + اضافه کن' : 'No tasks in this plan yet\nTap + to add one';

  // ── صفحهٔ جزئیاتِ ایده ─────────────────────────────────────────────────────
  String get ideaDetailTitle  => _fa ? 'ایده'              : 'Idea';
  String get addTime          => _fa ? 'افزودن زمان'       : 'Add time';
  String get noteHint         => _fa ? 'یادداشت…'          : 'Note…';

  // ── اکشن‌های مشترک ────────────────────────────────────────────────────────
  String get viewLabel        => _fa ? 'مشاهده'        : 'View';
  String get deleteLabel      => _fa ? 'حذف'           : 'Delete';
  String get renameLabel      => _fa ? 'تغییر نام'     : 'Rename';
  String get cancelLabel      => _fa ? 'لغو'           : 'Cancel';
  String get saveLabel        => _fa ? 'ذخیره'         : 'Save';
  String get deleteConfirmQ   => _fa ? 'حذف شود؟'      : 'Delete?';
  String get deleteConfirmMsg => _fa ? 'این مورد حذف می‌شود.' : 'This item will be deleted.';

  // ── صفحهٔ امروز ───────────────────────────────────────────────────────────
  String get newTaskHint => _fa ? 'کار جدید…'                 : 'New task…';
  String get emptyDay    => _fa ? 'برای افزودن کار، + را بزن' : 'Tap + to add a task';

  // ── مرتب‌سازی ─────────────────────────────────────────────────────────────
  String get sortDefault     => _fa ? 'پیش‌فرض (فوکوس، عادی، انجام‌شده)' : 'Default (Focus → Normal → Done)';
  String get sortTimeFirst   => _fa ? 'اول زمان‌دارها'  : 'Time first';
  String get sortStatusOrder => _fa ? 'بر اساس وضعیت'  : 'Status order';
  String get sortManual      => _fa ? 'دستی (کشیدن)'   : 'Manual (Drag)';

  // ── تنظیمات و تقویم ───────────────────────────────────────────────────────
String get language       => _fa ? 'زبان'      : 'Language';
String get calendarSystem => _fa ? 'نوع تقویم' : 'Calendar system';
String get calShamsi      => _fa ? 'شمسی'      : 'Shamsi';
String get calGregorian   => _fa ? 'میلادی'    : 'Gregorian';
String get week           => _fa ? 'هفته'      : 'Week';
String get month          => _fa ? 'ماه'       : 'Month';
String get today          => _fa ? 'امروز'     : 'Today';
String get calEmptyDay    => _fa ? 'برای این روز کاری نیست' : 'No tasks for this day';
// ── تنظیماتِ ظاهری، حساب و داده ──
String get appearance   => _fa ? 'ظاهر'            : 'Appearance';
String get theme        => _fa ? 'تم'              : 'Theme';
String get themeLight   => _fa ? 'روشن'            : 'Light';
String get themeDark    => _fa ? 'تاریک'           : 'Dark';
String get themeSystem  => _fa ? 'سیستم'           : 'System';
String get fontSize     => _fa ? 'اندازهٔ فونت'    : 'Font size';
String get fontSmall    => _fa ? 'کوچک'            : 'Small';
String get fontMedium   => _fa ? 'متوسط'           : 'Medium';
String get fontLarge    => _fa ? 'بزرگ'            : 'Large';
String get notifications     => _fa ? 'نوتیفیکیشن'     : 'Notifications';
String get notificationsDesc => _fa ? 'یادآوریِ کارها' : 'Task reminders';
String get username     => _fa ? 'نام کاربری'      : 'Username';
String get usernameHint => _fa ? 'اسمت رو بنویس…'  : 'Your name…';
String get account      => _fa ? 'حساب کاربری'     : 'Account';
String get accountComingSoon => _fa ? 'به‌زودی — نسخهٔ تیمی' : 'Coming soon — Team version';
String get about        => _fa ? 'درباره'          : 'About';
String get version      => _fa ? 'نسخه'            : 'Version';
String get clearData        => _fa ? 'پاک‌کردنِ داده‌ها' : 'Clear data';
String get clearDataDesc    => _fa ? 'همهٔ کارها، برنامه‌ها و ایده‌ها حذف می‌شوند' : 'Delete all tasks, plans and ideas';
String get clearDataQ       => _fa ? 'همه‌چیز پاک شود؟' : 'Clear everything?';
String get clearDataMsg     => _fa ? 'این کار همهٔ داده‌های اپ را برای همیشه حذف می‌کند و قابل بازگشت نیست.' : 'This permanently deletes all app data and cannot be undone.';
String get clearDataConfirm => _fa ? 'بله، همه پاک شود' : 'Yes, clear all';
String get clearedMsg       => _fa ? 'همه‌چیز پاک شد ✓' : 'All cleared ✓';
}
