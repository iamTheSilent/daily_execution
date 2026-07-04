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
}