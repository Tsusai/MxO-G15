(*Taken from
http://read.pudn.com/downloads24/sourcecode/delphi_control/76496/
Delphi%E6%8A%80%E6%9C%AF%E6%89%8B%E5%86%8C%E6%BA%90%E7%A0%81/
Delphi%E6%8A%80%E6%9C%AF%E6%89%8B%E5%86%8C%E6%BA%90%E7%A0%81/
nutshl50/Dates.pas__.htm
*)

unit Dates;

interface

uses Windows, SysUtils;

// Convert a local time to UTC by adding the time zone bias.
// To convert from UTC back to local, subtract the bias.
function LocalToUTC(DateTime: TDateTime): TDateTime;

// Convert UTC to local time.
function UTCtoLocal(DateTime: TDateTime): TDateTime;

// Parse a string as a date and time.   
function StringToDateTime(const S: string): TDateTime;   
   
// Convert a UNIX date and time to a Delphi TDateTime.   
function UnixtoDateTime(UnixTime: Int64): TDateTime;   
// Convert a TDateTime to a UNIX date and time.   
function DateTimeToUnix(DateTime: TDateTime): Int64;   
   
implementation
uses Variants;   
   
const   
  MinutesPerDay = 24 * 60;   
   
// Given a transition system time, return a TDateTime for the actual   
// transition date and time in the year of the DateTime argument.   
// If the system time is in absolute format, simply convert it.   
// Otherwise, the system time specifies a month, a day of the week, and   
// a week of the month in the year given by DateTime.   
function ComputeTzDate(DateTime: TDateTime; const SystemTime: TSystemTime): TDateTime;   
const   
  DaysPerWeek = 7;   
var   
  Year, Month, Day: Word;   
  DoW: 0..DaysPerWeek-1; // 0=Sunday, ..., 6=Saturday   
begin   
  if SystemTime.wYear <> 0 then   
    Result := SystemTimeToDateTime(SystemTime)   
  else   
  begin   
    // Get the year.   
    DecodeDate(DateTime, Year, Month, Day);   
		// Determine the day of the week for the first day of the month.
    // SystemTime uses 0=Sunday; DayOfWeek uses 1=Sunday,   
    // so subtract 1 to get 0..6.   
    Result := EncodeDate(Year, SystemTime.wMonth, 1);   
    DoW := DayOfWeek(Result) - 1;   
   
    // Find the day number of the first day of the month that matches   
    // the SystemTime.wDayOfWeek. The answer must be in the range 1..7.   
    // In other words, if the transition day is on Tuesday, Day is set   
    // to the day number of the first Tuesday of the month.   
    Day := (DaysPerWeek + SystemTime.wDayOfWeek - DoW) mod DaysPerWeek + 1;   
   
    // Add 7 for each week of the month (after the first).   
    Day := Day + DaysPerWeek * (SystemTime.wDay - 1);   
   
    // If wDay = 5, that means the last week of the month, which might be   
    // week 4 or week 5. Day hass been set for week 5. If the Day is beyond   
    // the end of the month, subtract one week.   
    if Day > SysUtils.MonthDays[IsLeapYear(Year), SystemTime.wMonth] then   
      Dec(Day, DaysPerWeek);   
    // Return the resulting date and time as a TDateTime.   
    with SystemTime do   
      Result := EncodeDate(Year, wMonth, Day) +   
                EncodeTime(wHour, wMinute, wSecond, wMilliseconds);   
  end;   
end;   
   
// Return True if the given TDateTime represents a date and time   
// that is in daylight savings time. Return False for standard   
// time or if the daylight savings time status cannot be determined.   
function IsDaylightSavingsTime(DateTime: TDateTime; const TzInfo: TTimeZoneInformation): Boolean;   
var   
	StandardDate, DaylightDate: TDateTime;
begin   
  if TzInfo.StandardDate.wMonth = 0 then   
    Result := False   
  else if TzInfo.DaylightDate.wMonth = 0 then   
    Result := False   
  else   
  begin   
    StandardDate := ComputeTzDate(DateTime, TzInfo.StandardDate);   
    DaylightDate := ComputeTzDate(DateTime, TzInfo.DaylightDate);   
    // DaylightDate is the date and time when daylight savings time begins,   
    // in the same year as DateTime. StandardDate is the date and time   
    // when daylight savings time ends in the same year.   
    Assert(StandardDate > DaylightDate);   
    Result := (DateTime >= DaylightDate) and (DateTime <= StandardDate);   
  end;   
end;   
   
// Convert a local time to UTC by adding the time zone bias.   
// To convert from UTC back to local, subtract the bias.   
function LocalToUTC(DateTime: TDateTime): TDateTime;   
var   
  Info: TTimeZoneInformation;   
  Bias: LongInt;   
begin   
  case GetTimeZoneInformation(Info) of   
  Time_Zone_Id_Standard, Time_Zone_Id_Daylight:   
  begin   
    // The value returned by GetTimeZoneInformation is for the current   
    // date and time, not for DateTime. Determine whether DateTime   
    // is in standard or daylight savings time.   
    if IsDaylightSavingsTime(DateTime, Info) then   
			Bias := Info.Bias + Info.DaylightBias
    else   
      Bias := Info.Bias + Info.StandardBias;   
   
    Result := DateTime + Bias / MinutesPerDay;   
  end;   
  Time_Zone_Id_Unknown:   
    Result := DateTime + Info.Bias / MinutesPerDay;   
  else   
    RaiseLastWin32Error;   
    Result := DateTime; // turn off Delphi's warning   
  end;   
end;   
   
// Convert UTC to local time.   
function UTCtoLocal(DateTime: TDateTime): TDateTime;   
var   
  Info: TTimeZoneInformation;   
begin   
  case GetTimeZoneInformation(Info) of   
  Time_Zone_Id_Standard, Time_Zone_Id_Daylight:   
  begin   
    // The value returned by GetTimeZoneInformation is for the current   
    // date and time, not for DateTime. Determine whether DateTime   
    // is in standard or daylight savings time.   
   
    // First get the local time, assuming that time is in standard time.   
    Result := DateTime - (Info.Bias + Info.StandardBias) / MinutesPerDay;   
    // Then check whether that time falls in daylight savings time.   
    if IsDaylightSavingsTime(Result, Info) then   
      // Recompute the date and time for daylight savings time.   
      Result := DateTime - (Info.Bias + Info.DaylightBias) / MinutesPerDay;   
  end;   
  Time_Zone_Id_Unknown:   
    Result := DateTime - Info.Bias / MinutesPerDay;   
  else   
    RaiseLastWin32Error;   
    Result := DateTime; // turn off Delphi's warning   
  end;   
end;   
   
// Parse a string as a date and time.   
function StringToDateTime(const S: string): TDateTime;   
var   
  V: Variant;   
begin   
  V := S;   
	Result := VarToDateTime(V);
end;   
   
const   
  UnixEpoch = 25569; // EncodeDate(1970, 1, 1)   
   
// Convert a UNIX date and time to a Delphi TDateTime (UTC).   
function UnixtoDateTime(UnixTime: Int64): TDateTime;   
begin   
  Result := UnixTime / SecsPerDay + UnixEpoch;   
end;   
   
// Convert a TDateTime (UTC) to a UNIX date and time.   
function DateTimeToUnix(DateTime: TDateTime): Int64;   
begin   
  Result := Round((DateTime - UnixEpoch) * SecsPerDay);   
end;   
   
end.
