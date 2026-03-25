/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Util
 * @description Date util
 * @changehistory
 * ISS-001922 01-07-2024 VTan - new class
 */
public inherited sharing class REDU_Date_UTIL {

    /**
     * @description Monday = 1
     */
    public static final Integer MONDAY = 1;

    /**
     * @description Tuesday = 2
     */
    public static final Integer TUESDAY = 2;

    /**
     * @description Wednesday = 3
     */
    public static final Integer WEDNESDAY = 3;

    /**
     * @description Thursday = 4
     */
    public static final Integer THURSDAY = 4;

    /**
     * @description Friday = 5
     */
    public static final Integer FRIDAY = 5;

    /**
     * @description Saturday = 6
     */
    public static final Integer SATURDAY = 6;

    /**
     * @description Sunday = 7
     */
    public static final Integer SUNDAY = 7;

    /**
     * @description Monday in Salesforce format = 2
     */
    public static final Integer SF_MONDAY = 2;

    /**
     * @description Tuesday in Salesforce format = 3
     */
    public static final Integer SF_TUESDAY = 3;

    /**
     * @description Wednesday in Salesforce format = 4
     */
    public static final Integer SF_WEDNESDAY = 4;

    /**
     * @description Thursday in Salesforce format = 5
     */
    public static final Integer SF_THURSDAY = 5;

    /**
     * @description Friday in Salesforce format = 6
     */
    public static final Integer SF_FRIDAY = 6;

    /**
     * @description Saturday in Salesforce format = 7
     */
    public static final Integer SF_SATURDAY = 7;

    /**
     * @description Sunday in Salesforce format = 1
     */
    public static final Integer SF_SUNDAY = 1;
    
    // Method to get ISO week number and year from a given date
    public static List<Integer> getISOWeekNumberAndYear(Date inputDate) {

        Integer year = inputDate.year();
        Integer dayOfYear = inputDate.dayOfYear();

        DateTime weekDayTemp = DateTime.newInstanceGmt(inputDate.year(), inputDate.month(), inputDate.day());
        Integer dayOfWeek = Integer.valueOf(weekDayTemp.formatGmt('u'));

        Integer daysToAdd = 4 - dayOfWeek; // Thursday is ISO standard starting day
        
        // Adjust the date to the Thursday of the same week
        Date thursdayOfSameWeek = inputDate.addDays(daysToAdd);
        
        // Calculate the week number
        Integer weekNumber = (thursdayOfSameWeek.dayOfYear() - 1) / 7 + 1;
        
        // Check if the week belongs to the previous year
        if (inputDate.month() == 1 && thursdayOfSameWeek.month() == 12) {
            year = year - 1;
        }
        // Check if the week belongs to the next year
        else if (inputDate.month() == 12 && thursdayOfSameWeek.month() == 1) {
            year = year + 1;
            weekNumber = 1;
        }
        
        REDU_Logging_UTIL.debug('ISO Week Number',  weekNumber);
        REDU_Logging_UTIL.debug('ISO Year', year);

        return new List<Integer>{weekNumber, year};
    }

    /**
     * @description Convert a Date/time to a specific timezone.
     * @param originalDateTime Date/time to be converted
     * @param fromTimezone Related timezone SID of originalDateTime
     * @param toTimezone Timezone SID to be converted to
     * @return DateTime
     */
    public static DateTime convertDateTime(DateTime originalDateTime, String fromTimezone, String toTimezone){
        String dateTimeFromStr = originalDateTime.format('yyyy-MM-dd HH:mm:ss', fromTimezone);
        String dateTimeToStr = originalDateTime.format('yyyy-MM-dd HH:mm:ss', toTimezone);
        Datetime fromDateTime = DateTime.valueOf(dateTimeFromStr);
        Datetime toDateTime = DateTime.valueOf(dateTimeToStr);
        Long milliSecDiff = fromDateTime.getTime() - toDateTime.getTime();
        Long minDiff = milliSecDiff / 1000 / 60;
        Datetime convertedDateTime = originalDateTime.addMinutes(minDiff.intValue());
        
        return convertedDateTime;
    }

    /**
    * @description Gets day in salesforce format or for first week of April 2018 (Used in dateless calendars)
    * @param dt date/time to be converted
    * @param sfFormat use sf format
    * @return Integer SF Format = (Sunday = 1, Monday = 2, Tuesday = 3, Wednesday = 4, Thursday = 5, Friday = 6, Saturday = 7)
        Java simple  = (Sunday = 7, Monday = 1, Tuesday = 2, Wednesday = 3, Thursday = 4, Friday = 5, Saturday = 6)
    */
    public static Integer getDay(DateTime dt, boolean sfFormat){
        String dayString = dt.format('EEEE');
        
        REDU_Logging_UTIL.debug('getDay', dayString);

        if (dayString == 'Monday'){
            return sfFormat ? SF_MONDAY : MONDAY;
        } else if (dayString == 'Tuesday'){
            return sfFormat ? SF_TUESDAY : TUESDAY;
        } else if (dayString == 'Wednesday'){
            return sfFormat ? SF_WEDNESDAY : WEDNESDAY;
        } else if (dayString == 'Thursday'){
            return sfFormat ? SF_THURSDAY : THURSDAY;
        } else if (dayString == 'Friday'){
            return sfFormat ? SF_FRIDAY : FRIDAY;
        } else if (dayString == 'Saturday'){
            return sfFormat ? SF_SATURDAY : SATURDAY;
        } else {
            return sfFormat ? SF_SUNDAY : SUNDAY;
        }
    }
}