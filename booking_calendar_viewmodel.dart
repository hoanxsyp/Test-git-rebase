import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meeting/constants/setting_const.dart';
import 'package:flutter_meeting/constants/string_const.dart';
import 'package:flutter_meeting/data/models/api_input/meeting/create_meeting_input.dart';
import 'package:flutter_meeting/domain/entities/calendar/communicator_available_entity.dart';
import 'package:flutter_meeting/domain/entities/create_event/create_event_result_entity.dart';
import 'package:flutter_meeting/domain/entities/meeting/detail_event_entity.dart';
import 'package:flutter_meeting/domain/entities/notification/data_state_user_entity.dart';
import 'package:flutter_meeting/domain/entities/online_attendance/sc_date_meeting_info_entity.dart';
import 'package:flutter_meeting/domain/entities/prebook_calendar/sc_availability_entity.dart';
import 'package:flutter_meeting/domain/entities/user/user_entity_kpl.dart';
import 'package:flutter_meeting/foundation/architecture/mobx_viewmodel.dart';
import 'package:flutter_meeting/foundation/debug/logger.dart';
import 'package:flutter_meeting/foundation/extension/datetime_range_ext.dart';
import 'package:flutter_meeting/foundation/extension/extension.dart';
import 'package:flutter_meeting/scenes/booking_calendar/booking_calendar_navigator.dart';
import 'package:flutter_meeting/scenes/booking_calendar/booking_calendar_usecase.dart';
import 'package:flutter_meeting/scenes/common/table/calendar_builder/controller/calendar_builder_controller.dart';
import 'package:flutter_meeting/scenes/common/table/calendar_builder/controller/calendar_builder_item_controller.dart';
import 'package:flutter_meeting/scenes/common/table/calendar_builder/models/calendar_config.dart';
import 'package:flutter_meeting/scenes/common/table/calendar_builder/models/calendar_data_view.dart';
import 'package:flutter_meeting/scenes/create_event_douseki/create_event_douseki_viewmodel.dart';
import 'package:flutter_meeting/utils/app_enums.dart';
import 'package:get/get.dart' hide navigator;
import 'package:kalender/kalender.dart';
import 'package:mobx/mobx.dart';

part '../../generated/scenes/booking_calendar/booking_calendar_viewmodel.g.dart';

class BookingCalendarViewModel = _BookingCalendarViewModel with _$BookingCalendarViewModel;

abstract class _BookingCalendarViewModel extends MobXViewModel<BookingCalendarUseCase, BookingCalendarNavigator>
    with Store {
  _BookingCalendarViewModel(
    this.prebookingEvent,
    this._isCreateMode, {
    required this.groupId,
    // ignore: unused_element
    this.skillId,
  });

  ///* VARIABLE *///
  late String groupId;
  String? skillId;
  final daysPerWeek = 5;
  final startWork = const TimeOfDay(hour: 0, minute: 0);
  final endWork = const TimeOfDay(hour: 24, minute: 0);
  final reservePageController = CalendarBuilderController<CommunicatorAvailableEntity>(
    dateTimeRange: null,
    initialDate: DateTimeExt.nowJP().onlyDate,
  );
  final eventPageController = CalendarBuilderController<SCDateMeetingInfoEntity>(
    dateTimeRange: null,
    initialDate: DateTimeExt.nowJP().onlyDate,
  );
  final eventController = CalendarBuilderItemController<SCDateMeetingInfoEntity>();
  final reserveItemsController = CalendarBuilderItemController<CommunicatorAvailableEntity>();
  final reserveScrollController = ScrollController();
  final eventScrollController = ScrollController();

  final today = DateTimeExt.nowJP().onlyDate;

  Timer? _timer;

  DetailEventEntity? prebookingEvent;
  bool _isCreateMode = true;

  DateTime get startTimeOfDay => DateTimeExt.dateTime(today.year, today.month, today.day);
  DateTime get initialTargetHour => DateTimeExt.dateTime(today.year, today.month, today.day, hour: 8, minute: 0);
  CalendarConfig get config => WeekConfig(daysPerWeek: daysPerWeek);
  DateTime get startTimeCalendar => today;
  DateTime get endTimeCalendar => today.add(const Duration(days: SettingConstants.CUSTOM_CALENDAR_DURATION));

  ReactionDisposer? listenShowCalendar;
  ReactionDisposer? listenShowHourLine;

  StreamSubscription<DataStateUserEntity?>? _dataStateUserSubscription;

  ///* STATE *///
  @observable
  bool isLoading = false;

  @observable
  late DateTimeRange visibleDateRange = DateTimeRange(
    start: today,
    end: today.add(Duration(days: max(1, daysPerWeek - 1))),
  );

  @observable
  UserEntity? userInfo;

  @observable
  List<SCDateMeetingInfoEntity> scDateMeetingInfoList = [
    SCDateMeetingInfoEntity(
      meetingId: '5434936653_1777004543508',
      meetingShortId: '5434936653',
      passcode: '186045',
      meetingName: 'ｱｲﾝ_申込手続時オンライン同席',
      meetingType: 'realtime_sc',
      isScBooking: true,
      startTimeCalendar: DateTime(2026, 04, 24, 13, 22, 14),
      endTimeCalendar: DateTime(2026, 04, 24, 15, 22, 14),
      meetingStatus: MeetingStatus.scheduled,
      skillName: 'Test thoi',
      scMeetingInfo: SCMeetingInfoDataEntity(
        groupId: 'group20250401175930692KRv',
        memo: 'test',
        creatorName: '相談者＿０９９４００',
        phoneNumber: '0123456789',
        recipientCode: '11111111',
        localCode: '009400',
        email: 'consultant_009400@syp.vn',
        cmUserId: '5714fad8-30e1-702a-2c1c-35d2cf7ef2d4',
      ),
    ),
    SCDateMeetingInfoEntity(
      meetingId: '5434936653_1777004543509',
      meetingShortId: '5434936653',
      passcode: '186045',
      meetingName: 'ｱｲﾝ_申込手続時オンライン同席',
      meetingType: 'realtime_sc',
      isScBooking: true,
      startTimeCalendar: DateTime(2026, 04, 25, 13, 22, 14),
      endTimeCalendar: DateTime(2026, 04, 25, 15, 22, 14),
      meetingStatus: MeetingStatus.scheduled,
      skillName: 'Test thoi 2',
      scMeetingInfo: SCMeetingInfoDataEntity(
        groupId: 'group20250401175930692KRv',
        memo: 'test',
        creatorName: '相談者＿０９９４００',
        phoneNumber: '0123456789',
        recipientCode: '11111111',
        localCode: '009400',
        email: 'consultant_009400@syp.vn',
        cmUserId: '5714fad8-30e1-702a-2c1c-35d2cf7ef2d4',
      ),
    ),
  ];

  @observable
  ScAvailabilityEntity? scAvailability;

  @observable
  DateTime initialDate = DateTimeExt.nowJP();

  @observable
  DateTime currentTime = DateTimeExt.nowJP();

  @observable
  int meetingTimeIntervalInMinutes = SettingConstants.STEP_TIME;

  @observable
  bool loadSuccess = false;

  @observable
  bool initBookingCalendar = false;

  ///* COMPUTED *///
  @computed
  bool get isPreviousDisabled => visibleDateRange.start.isBefore(today) || visibleDateRange.start.isSameDay(today);

  @computed
  bool get isNextDisabled {
    return endTimeCalendar.isAfter(visibleDateRange.start) && endTimeCalendar.isBefore(visibleDateRange.end) ||
        endTimeCalendar.isSameDay(visibleDateRange.start) ||
        endTimeCalendar.isSameDay(visibleDateRange.end);
  }

  @computed
  bool get isCurrentWeek => visibleDateRange.start.isBefore(today) || visibleDateRange.start.isSameDay(today);

  @computed
  String get userName {
    userInfo = useCase.getLocalUser();
    return userInfo?.nameKanji ?? '';
  }

  @computed
  String get getDateRangeString {
    return visibleDateRange.dayRangeString();
  }

  @computed
  int get meetingTimeInMinutes => scAvailability?.meetingTimeInMinutes ?? SettingConstants.DEFAULT_MEETING_TIME;

  @computed
  Map<String, List<DateInfoEntity>> get scAvailableDates => scAvailability?.dates ?? {};

  @computed
  int get hourSlots => startWork.getSlotWorkCalendar(endWork, stepTime: meetingTimeIntervalInMinutes);

  @computed
  double get initialOffset => calculateOffsetY(initialTargetHour, meetingTimeIntervalInMinutes);

  @computed
  double get currentTimeOffsetY => calculateOffsetY(currentTime, meetingTimeIntervalInMinutes);

  @computed
  bool get showCalendar => !isLoading && loadSuccess;

  List<OrganizationFeature> get supportedFeatures => _getSupportedFeatures();

  bool get hasServiceCenterUseSkillFeature => supportedFeatures.contains(OrganizationFeature.serviceCenterUseSkill);

  bool get hasServiceCenterFeature => supportedFeatures.contains(OrganizationFeature.serviceCenter);

  ///* LIFE CYCLE *///
  @override
  void onInit() {
    initView();
    startTimer(const Duration(seconds: 1), () {
      currentTime = DateTimeExt.nowJP();
    });
    setupHourLineOffsetY();
    setupShowCalendar();
    super.onInit();
  }

  /// Check if the current date falls within the current date range
  /// If so, scroll to the offset that is one cell height away from the current time offset on the Y-axis
  /// Otherwise, always jump to the offset corresponding to 8:00 on the Y-axis
  void scrollToInitialOffset() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      const stepHeight = SettingConstants.ITEM_HEIGHT + SettingConstants.BORDER_WIDTH;
      final offset = !isCurrentWeek
          ? initialOffset
          : currentTimeOffsetY - stepHeight > 0
              ? currentTimeOffsetY - stepHeight
              : currentTimeOffsetY;

      await eventScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  String generateLink(String meetingShortId, String passCode) {
    if (meetingShortId.isEmpty && passCode.isEmpty) return '';
    return useCase.generateLink(meetingShortId, passCode);
  }

  void _syncScroll() {
    if (eventScrollController.hasClients && reserveScrollController.hasClients) {
      if (eventScrollController.offset != reserveScrollController.offset) {
        if (eventScrollController.position.isScrollingNotifier.value) {
          reserveScrollController.jumpTo(eventScrollController.offset);
        } else if (reserveScrollController.position.isScrollingNotifier.value) {
          eventScrollController.jumpTo(reserveScrollController.offset);
        }
      }
    }
  }

  void initView() {
    eventPageController.setHourLineOffsetY(currentTimeOffsetY);

    reservePageController.setHourLineOffsetY(currentTimeOffsetY);

    eventScrollController.addListener(_syncScroll);
    reserveScrollController.addListener(_syncScroll);
  }

  void setupHourLineOffsetY() {
    listenShowCalendar = reaction<double>((_) => currentTimeOffsetY, (offset) {
      eventPageController
        ..setHourLineOffsetY(offset)
        ..attach(eventPageController.state.value.config);

      reservePageController
        ..setHourLineOffsetY(offset)
        ..attach(reservePageController.state.value.config);
    });
  }

  void setupShowCalendar() {
    listenShowCalendar = reaction<bool>((_) => showCalendar, (isVisible) {
      eventPageController
        ..setShowHourLine(isVisible)
        ..attach(eventPageController.state.value.config);

      reservePageController
        ..setShowHourLine(isVisible)
        ..attach(reservePageController.state.value.config);

      scrollToInitialOffset();
    });
  }

  double calculateOffsetY(DateTime targetTime, int stepTime) {
    final minutesPassed = targetTime.difference(startTimeOfDay).inMinutes;
    const stepHeight = SettingConstants.ITEM_HEIGHT + SettingConstants.BORDER_WIDTH;
    return (minutesPassed / stepTime) * stepHeight;
  }

  @override
  void onReady() {
    visibleDateRange = reservePageController.visibleDateRange;
    reservePageController.visibleDateTimeRangeNotifier.addListener(() {
      if (visibleDateRange != reservePageController.visibleDateRange) {
        visibleDateRange = reservePageController.visibleDateRange;
        unawaited(initData());
      }
    });
    eventPageController.visibleDateTimeRangeNotifier.addListener(() {
      if (visibleDateRange != eventPageController.visibleDateRange) {
        visibleDateRange = eventPageController.visibleDateRange;
        unawaited(initData());
      }
    });
    _init();
    super.onReady();
  }

  void _init() {
    initListener();
    unawaited(
      Future.delayed(const Duration(milliseconds: 500)).then((_) async {
        await initData();
        initBookingCalendar = true;
      }),
    );
  }

  void startTimer(Duration duration, void Function() callback) {
    _timer?.cancel();
    _timer = Timer.periodic(duration, (timer) {
      final nowJP = DateTimeExt.nowJP();
      if (nowJP.second == 0) {
        callback();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> initData({bool isFetchedMeetings = true}) async {
    try {
      isLoading = true;

      eventController.clear();
      reserveItemsController.clear();

      await initScAvailability();

      await initScMeetings();

      unawaited(addDuplicatedMeetings());
    } catch (e) {
      logError('Error initData for BookingCalendarViewModel', error: e);
    } finally {
      isLoading = false;
    }
  }

  void initListener() {
    try {
      final userInfo = useCase.getLocalUser();
      final userId = userInfo?.id ?? '';
      final organizationId = userInfo?.organization?.id ?? '';
      if (userId.isEmpty || organizationId.isEmpty) return;
      _dataStateUserSubscription = useCase.listenFsDataStateUser(organizationId, userId).listen((dataState) {
        if (!initBookingCalendar) return;
        unawaited(initScMeetings());
      });
    } catch (e, stackTrace) {
      logError('Error in initListener', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> initScAvailability() async {
    await getScAvailability();
    reserveItemsController.addAll([...convertDatesToCalendarDataView()]);
  }

  Future<void> initScMeetings() async {
    await getScCmGroupMeetingList();
    eventController
      ..clear()
      ..addAll([...convertMeetingsToCalendarDataView()]);
  }

  @override
  void onClose() {
    reserveItemsController.dispose();
    reservePageController.dispose();
    eventPageController.dispose();
    eventController.dispose();
    eventScrollController.removeListener(_syncScroll);
    reserveScrollController.removeListener(_syncScroll);
    eventScrollController.dispose();
    reserveScrollController.dispose();
    stopTimer();
    listenShowCalendar?.call();
    listenShowHourLine?.call();
    unawaited(_dataStateUserSubscription?.cancel());
    super.onClose();
  }

  ///* ACTIONS *///

  @action
  void animateToSelectedDate(DateTime? selectedDate) {
    if (selectedDate == null || visibleDateRange.start.isSameDay(selectedDate)) return;
    updateCalendarForSelectedDate(selectedDate);
  }

  @action
  void previousPage() {
    if (!isPreviousDisabled) {
      final selectedDate = visibleDateRange.start.subtract(Duration(days: daysPerWeek));
      updateCalendarForSelectedDate(selectedDate);
    }
  }

  @action
  void nextPage() {
    final selectedDate = visibleDateRange.start.add(Duration(days: daysPerWeek));
    updateCalendarForSelectedDate(selectedDate);
  }

  @action
  void todayPage() {
    if (!visibleDateRange.start.isSameDay(today)) {
      updateCalendarForSelectedDate(today);
    }
  }

  void updateCalendarForSelectedDate(DateTime selectedDate) {
    initialDate = selectedDate;

    eventController.clear();
    reserveItemsController.clear();

    reservePageController
      ..setDateTimeRange(selectedDate)
      ..setSelectedDate(selectedDate)
      ..attach(reservePageController.state.value.config);
    eventPageController
      ..setDateTimeRange(selectedDate)
      ..setSelectedDate(selectedDate)
      ..attach(reservePageController.state.value.config);
  }

  @action
  Future<void> onCreateMeeting(DateTime start) async {
    final DateTime startJP =
        DateTimeExt.dateTime(start.year, start.month, start.day, hour: start.hour, minute: start.minute);
    final endJP = startJP.add(Duration(minutes: meetingTimeInMinutes));
    if (_isCreateMode) {
      final result = await navigator.toCreateEventDousekiDialog(
        startDate: startJP,
        initEvent: prebookingEvent?.copyWith(
          startTime: startJP,
          endTime: endJP,
        ),
        scMeetingInfo: ScMeetingInfoInput(
          memo: prebookingEvent?.scMeetingInfo?.memo,
          phoneNumber: prebookingEvent?.scMeetingInfo?.phoneNumber,
          groupId: groupId,
        ),
        meetingTime: meetingTimeInMinutes,
        isCreateMode: _isCreateMode,
        skillId: skillId,
      );

      if (result is CreateEventResultEntity) {
        _isCreateMode = true;
        prebookingEvent = null;
        await initData();
      }
    } else {
      if (Get.isRegistered<CreateEventDousekiViewModel>()) {
        Get.find<CreateEventDousekiViewModel>().updateInitEvent(MeetingType.prebook_sc, startJP, endJP);
      }
      await onBackPressed();
    }
  }

  @action
  Future<void> onBackPressed() async {
    navigator.back();
  }

  Future<void> getScCmGroupMeetingList() async {
    try {
      // scDateMeetingInfoList =
      //     await useCase.getScCmGroupMeetingList(visibleDateRange.start, visibleDateRange.end, userInfo?.id ?? '', true);
      loadSuccess = true;
    } catch (e) {
      scDateMeetingInfoList = [];
      loadSuccess = false;
      logError('Error getScCmGroupMeetingList', error: e);
    }
  }

  Future<void> getScAvailability() async {
    try {
      final startDate = today.isAfter(visibleDateRange.start) ? today : visibleDateRange.start;
      scAvailability = await useCase.getScAvailability(groupId, startDate, visibleDateRange.end, skillId: skillId);
      loadSuccess = true;
    } catch (e) {
      scAvailability = null;
      loadSuccess = false;
      logError('Error getScAvailability', error: e);
    } finally {
      meetingTimeIntervalInMinutes = max(1, scAvailability?.meetingTimeIntervalInMinutes ?? SettingConstants.STEP_TIME);
    }
  }

  List<CalendarDataView<SCDateMeetingInfoEntity>> convertMeetingsToCalendarDataView() {
    final List<CalendarDataView<SCDateMeetingInfoEntity>> calendarDataViews = [];
    final Set<String> setMeetingIds = {};

    for (final meeting in scDateMeetingInfoList) {
      if (meeting.meetingId == null || meeting.startTimeCalendar == null || meeting.endTimeCalendar == null) {
        continue;
      }

      //Skip duplicated element
      if (setMeetingIds.add(meeting.meetingId!)) {
        final calendarData = CalendarDataView<SCDateMeetingInfoEntity>(
          id: generateDistinctMeetingID(meeting, meeting.startTimeCalendar!),
          start: meeting.startTimeCalendar!,
          end: meeting.endTimeCalendar!,
          data: meeting,
        );
        calendarDataViews.add(calendarData);
      }
    }

    return calendarDataViews;
  }

  /// Function to add duplicate meetings to eventController
  /// Purpose: Split meetings with start and end dates spanning multiple days into separate meetings for each day
  Future<void> addDuplicatedMeetings() async {
    for (final meeting in scDateMeetingInfoList) {
      if (meeting.meetingId == null || meeting.startTimeCalendar == null || meeting.endTimeCalendar == null) {
        continue;
      }

      // Get the start date and end date of the meeting
      DateTime startDate = meeting.startTimeCalendar!;
      final endTimeCalendar = meeting.endTimeCalendar!;

      // Loop through each day from startDate to the day before endTimeCalendar
      while (startDate.onlyDate.isBefore(endTimeCalendar.onlyDate)) {
        final endDate = DateTimeExt.dateTime(startDate.year, startDate.month, startDate.day, hour: 23, minute: 59);
        final String uniqueId = generateDistinctMeetingID(meeting, startDate);

        if (!eventController.containsById(uniqueId)) {
          final calendarData = CalendarDataView<SCDateMeetingInfoEntity>(
            id: uniqueId,
            start: startDate,
            end: endDate,
            data: meeting,
          );
          eventController.add(calendarData);
        }
        startDate = DateTimeExt.dateTime(startDate.year, startDate.month, startDate.day + 1);
      }

      // Handle the last day of the meeting
      final String finalDayId = generateDistinctMeetingID(meeting, startDate);
      if (startDate.isSameDay(endTimeCalendar) && !eventController.containsById(finalDayId)) {
        final calendarData = CalendarDataView<SCDateMeetingInfoEntity>(
          id: finalDayId,
          start: startDate,
          end: endTimeCalendar,
          data: meeting,
        );
        eventController.add(calendarData);
      }
    }
  }

  String generateDistinctMeetingID(SCDateMeetingInfoEntity meeting, DateTime startDate) {
    return '${meeting.meetingId!}_$startDate';
  }

  bool isPassedTime(DateTime start, DateTime current, int reservationDelayInMinutes) {
    final startJP = DateTimeExt.dateTime(start.year, start.month, start.day, hour: start.hour, minute: start.minute);
    final adjustedNow = current.add(Duration(minutes: reservationDelayInMinutes));
    return startJP.roundMinutes(step: meetingTimeIntervalInMinutes).isBefore(adjustedNow);
  }

  List<CalendarDataView<CommunicatorAvailableEntity>> convertDatesToCalendarDataView() {
    if (scAvailability?.dates == null) return [];

    final List<CalendarDataView<CommunicatorAvailableEntity>> calendarDataViews = [];
    final Set<String> addedStartTimes = {};

    // Loop through visibleDateRange to check which days are missing from scAvailability?.dates
    for (DateTime currentDate = visibleDateRange.start;
        currentDate.isBefore(visibleDateRange.end) || currentDate.isSameDay(visibleDateRange.end);
        currentDate = currentDate.add(const Duration(days: 1))) {
      final dateString = DateFormat(AppDateFormat.yyyyMMddSlash).format(currentDate);
      final dateInfoList = scAvailableDates[dateString];

      // Check if this date is missing from scAvailability?.dates
      if (dateInfoList == null || dateInfoList.isEmpty || currentDate.onlyDate.isBefore(today)) {
        final calendarDataList = generateEmptyCalendarDataList(currentDate.onlyDate);
        calendarDataViews.addAll([...calendarDataList]);
        continue;
      }

      // If there is data for this day, add to calendarDataViews
      for (final dateInfo in dateInfoList) {
        final startTime = DateFormat(AppDateFormat.HHmm).tryParse(dateInfo.startTime ?? '');

        if (startTime == null) continue;

        final start = currentDate.add(Duration(hours: startTime.hour, minutes: startTime.minute));
        final end = start.add(Duration(minutes: meetingTimeIntervalInMinutes));

        // If the current time has passed, set status to 'not available'
        final status = isPassedTime(start, currentTime, scAvailability?.reservationDelayInMinutes ?? 0)
            ? CommunicatorStatus.notAvailable
            : _getCommunicatorStatus(dateInfo.availableCmCount);

        // Skip duplicated elements
        if (addedStartTimes.add(start.toString())) {
          final calendarData = CalendarDataView<CommunicatorAvailableEntity>(
            id: start.toString(),
            start: start,
            end: end,
            data: CommunicatorAvailableEntity(
              status: status,
              time: start,
              remaining: status == CommunicatorStatus.remaining ? (dateInfo.availableCmCount ?? 0) : 0,
            ),
          );

          calendarDataViews.add(calendarData);
        }
      }
    }

    return calendarDataViews;
  }

  List<CalendarDataView<CommunicatorAvailableEntity>> generateEmptyCalendarDataList(DateTime currentDate) {
    return List.generate(hourSlots, (int index) {
      final start = currentDate.add(Duration(minutes: index * meetingTimeIntervalInMinutes));
      final end = start.add(Duration(minutes: meetingTimeIntervalInMinutes));
      return CalendarDataView<CommunicatorAvailableEntity>(
        id: start.toString(),
        start: start,
        end: end,
        data: CommunicatorAvailableEntity(
          status: CommunicatorStatus.notAvailable,
          time: start,
        ),
      );
    });
  }

  CommunicatorStatus _getCommunicatorStatus(int? availableCmCount) {
    return availableCmCount == null
        ? CommunicatorStatus.notAvailable
        : availableCmCount == 0
            ? CommunicatorStatus.full
            : availableCmCount == 1
                ? CommunicatorStatus.fewLeft
                : CommunicatorStatus.remaining;
  }

  List<OrganizationFeature> _getSupportedFeatures() {
    return useCase.getSupportedFeatures();
  }
}

extension TimeExtension on BookingCalendarViewModel {
  String getTimeLineString(int row) {
    final totalMinutes = row * meetingTimeIntervalInMinutes + startWork.hour * 60 + startWork.minute;

    final hour = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minute = (totalMinutes % 60).toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  DateTime getOnlyDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

extension BookingEvent on BookingCalendarViewModel {
  void updateInitBookingEvent(DetailEventEntity? event, bool isCreateMode) {
    prebookingEvent = event;
    _isCreateMode = isCreateMode;
  }
}
