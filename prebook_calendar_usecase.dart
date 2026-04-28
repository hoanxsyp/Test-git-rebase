import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_meeting/constants/string_const.dart';
import 'package:flutter_meeting/data/api/apis/api_prebook_calendar.dart';
import 'package:flutter_meeting/data/models/api_input/prebook_calendar/get_sc_availability_input.dart';
import 'package:flutter_meeting/data/models/api_input/service_center/get_meetings_input.dart';
import 'package:flutter_meeting/domain/entities/online_attendance/sc_date_meeting_info_entity.dart';
import 'package:flutter_meeting/domain/entities/prebook_calendar/sc_availability_entity.dart';
import 'package:flutter_meeting/generated/app_repository.g.dart';
import 'package:flutter_meeting/utils/app_enums.dart';
import 'package:get/get.dart';

class PrebookCalendarUseCase {
  final repository = Get.find<AppRepository>();

  Future<List<SCDateMeetingInfoEntity>> getScCmGroupMeetingList(
    DateTime from,
    DateTime to,
    String userId, [
    bool? getMeetingDetailFlg,
  ]) async {
    final getMeetingsInput = GetMeetingsInput(
      from: DateFormat(AppDateFormat.yyyyMMddSlash, StringConstants.LOCALE_JA).format(from),
      to: DateFormat(AppDateFormat.yyyyMMddSlash, StringConstants.LOCALE_JA).format(to),
      getMeetingDetailFlg: true,
    );

    // [MOCK] Call repository to check params but return mock data
    try {
      await APIPrebookCalendar.shared.getScCmGroupMeetingList(getMeetingsInput);
    } catch (_) {}
    return _getMockScCmGroupMeetingList(from);
  }

  List<SCDateMeetingInfoEntity> _getMockScCmGroupMeetingList(DateTime from) {
    return [
      SCDateMeetingInfoEntity(
        meetingId: 'mock_meeting_1',
        meetingShortId: '1234567890',
        passcode: '111111',
        meetingName: 'Mock Meeting 1',
        meetingType: 'realtime_sc',
        isScBooking: true,
        startTimeCalendar: DateTime(from.year, from.month, from.day, 14, 0),
        endTimeCalendar: DateTime(from.year, from.month, from.day, 15, 0),
        meetingStatus: MeetingStatus.scheduled,
        skillName: 'General Support',
        scMeetingInfo: SCMeetingInfoDataEntity(
          memo: 'Mock memo',
          cmUserId: 'mock_cm_1',
          groupId: 'mock_group_1',
          recipientCode: 'R001',
          localCode: 'L001',
          creatorName: 'Test Creator',
          phoneNumber: '090-1234-5678',
          email: 'test@example.com',
        ),
      ),
      SCDateMeetingInfoEntity(
        meetingId: 'mock_meeting_2',
        meetingShortId: '0987654321',
        passcode: '222222',
        meetingName: 'Mock Meeting 2',
        meetingType: 'realtime_sc',
        isScBooking: true,
        startTimeCalendar: DateTime(from.year, from.month, from.day + 1, 14, 0),
        endTimeCalendar: DateTime(from.year, from.month, from.day + 1, 15, 0),
        meetingStatus: MeetingStatus.started,
        skillName: 'General Support',
        scMeetingInfo: SCMeetingInfoDataEntity(
          memo: 'Mock memo',
          cmUserId: 'mock_cm_1',
          groupId: 'mock_group_1',
          recipientCode: 'R001',
          localCode: 'L001',
          creatorName: 'Test Creator',
          phoneNumber: '090-1234-5678',
          email: 'test@example.com',
        ),
      ),
    ];
  }

  Future<ScAvailabilityEntity> getScAvailability(String groupId, DateTime from, DateTime to, {String? skillId}) async {
    final getScAvailabilityInput = GetScAvailabilityInput(
      groupId: groupId,
      from: DateFormat(AppDateFormat.yyyyMMddSlash).format(from),
      to: DateFormat(AppDateFormat.yyyyMMddSlash).format(to),
      skillId: skillId,
    );

    // [MOCK] Call repository to check params but return mock data
    try {
      await APIPrebookCalendar.shared.getSCAvailability(getScAvailabilityInput);
    } catch (_) {}
    return _getMockScAvailability(from, to);
  }

  ScAvailabilityEntity _getMockScAvailability(DateTime from, DateTime to) {
    final Map<String, List<DateInfoEntity>> mockDates = {};

    for (int i = 0; i <= to.difference(from).inDays; i++) {
      final date = from.add(Duration(days: i));
      final dateString = DateFormat(AppDateFormat.yyyyMMddSlash).format(date);

      mockDates[dateString] = [
        DateInfoEntity(startTime: '09:00', availableCmCount: 2),
        DateInfoEntity(startTime: '09:30', availableCmCount: 0),
        DateInfoEntity(startTime: '10:00', availableCmCount: 1),
        DateInfoEntity(startTime: '10:30', availableCmCount: 5),
        DateInfoEntity(startTime: '11:00', availableCmCount: 2),
        DateInfoEntity(startTime: '11:30', availableCmCount: 1),
        DateInfoEntity(startTime: '13:00', availableCmCount: 3),
        DateInfoEntity(startTime: '13:30', availableCmCount: 0),
        DateInfoEntity(startTime: '14:00', availableCmCount: 4),
        DateInfoEntity(startTime: '14:30', availableCmCount: 2),
        DateInfoEntity(startTime: '15:00', availableCmCount: 1),
        DateInfoEntity(startTime: '15:30', availableCmCount: 5),
      ];
    }

    return ScAvailabilityEntity(
      meetingTimeIntervalInMinutes: 30,
      meetingTimeInMinutes: 60,
      reservationAvailableDays: 30,
      reservationDelayInMinutes: 0,
      dates: mockDates,
    );
  }
}
