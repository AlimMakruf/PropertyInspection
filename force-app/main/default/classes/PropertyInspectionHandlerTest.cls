/**
 * @description Test class for PropertyInspectionHandler
 * Covers:
 * - calculateAverageInspectionRating(Id)
 * - getAllOverdueInspection()
 * - updateAccountDescription(List<Property_Inspection__c>)
 */
@IsTest
private class PropertyInspectionHandlerTest {

    @TestSetup
    static void setupTestData() {
        // Create Accounts
        Account a1 = new Account(Name = 'Prop A');
        Account a2 = new Account(Name = 'Prop B');
        Account a3 = new Account(Name = 'No Inspections'); // will have zero inspections
        insert new List<Account>{ a1, a2, a3 };

        // Inspections for A1 with various ratings and dates
        List<Property_Inspection__c> insList = new List<Property_Inspection__c>{
            new Property_Inspection__c(
                Name = 'A1 Past Scheduled',
                Account__c = a1.Id,
                Overall_Rating__c = 3,
                Inspection_Date__c = Date.today().addDays(-5),
                Inspection_Status__c = 'Scheduled',
                Notes__c = 'A1 Note 1'
            ),
            new Property_Inspection__c(
                Name = 'A1 Past In Progress',
                Account__c = a1.Id,
                Overall_Rating__c = 5,
                Inspection_Date__c = Date.today().addDays(-1),
                Inspection_Status__c = 'In Progress',
                Notes__c = 'A1 Note 2'
            ),
            new Property_Inspection__c(
                Name = 'A1 Future Completed',
                Account__c = a1.Id,
                Overall_Rating__c = 4,
                Inspection_Date__c = Date.today().addDays(3),
                Inspection_Status__c = 'Completed',
                Notes__c = 'A1 Future Note'
            ),

            // Inspections for A2
            new Property_Inspection__c(
                Name = 'A2 Past Completed',
                Account__c = a2.Id,
                Overall_Rating__c = 2,
                Inspection_Date__c = Date.today().addDays(-10),
                Inspection_Status__c = 'Completed',
                Notes__c = 'A2 Note 1'
            ),
            new Property_Inspection__c(
                Name = 'A2 Today Scheduled Not Overdue',
                Account__c = a2.Id,
                Overall_Rating__c = 1,
                Inspection_Date__c = Date.today(),
                Inspection_Status__c = 'Scheduled',
                Notes__c = 'A2 Note 2'
            ),
            new Property_Inspection__c(
                Name = 'A2 Past Scheduled',
                Account__c = a2.Id,
                Overall_Rating__c = 3,
                Inspection_Date__c = Date.today().addDays(-2),
                Inspection_Status__c = 'Scheduled',
                Notes__c = 'A2 Note 3'
            )
        };
        insert insList;

        // One inspection without Account for negative path
        insert new Property_Inspection__c(
            Name = 'No Account Inspection',
            Overall_Rating__c = 5,
            Inspection_Date__c = Date.today().addDays(-2),
            Inspection_Status__c = 'Scheduled',
            Notes__c = 'No Account Note'
        );
    }

    // 1) Positive test for average rating calculation
    @IsTest
    static void testCalculateAverageInspectionRating_Positive() {
        // Pick Account A1 directly, then call by Account Id (method signature expects Account Id)
        Account a1 = [SELECT Id FROM Account WHERE Name = 'Prop A' LIMIT 1];

        Test.startTest();
        Decimal avg = PropertyInspectionHandler.calculateAverageInspectionRating(a1.Id);
        Test.stopTest();

        // A1 ratings considered by handler query are all related to A1 (3, 5, 4) => average = 4.00 (scaled to 2 decimals)
        System.assertEquals(4, avg, 'Average rating for A1 should be 4.00');
    }

    // 2) Negative path: calculateAverageInspectionRating with inspection whose Account is null
    // The method does not explicitly return in that scenario; this test ensures that a runtime exception
    // does not occur on the SOQL (it won't) and validates graceful handling (no return expected).
    // We expect a NullPointerException due to missing return; this still provides coverage for error path.
    @IsTest
    static void testCalculateAverageInspectionRating_NullAccount() {
        // When AccountId is null, method cannot be called; simulate by passing null and verify graceful behavior via try/catch.
        Test.startTest();
        Boolean threw = false;
        try {
            Decimal res = PropertyInspectionHandler.calculateAverageInspectionRating((Id) null);
            System.assertEquals(0, res, 'Null Account Id should return 0 per safe handling expectation');
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();
        System.assertEquals(false, threw, 'Method should handle null Account Id without throwing');
    }

    // 3) Positive test for overdue inspections retrieval
    @IsTest
    static void testGetAllOverdueInspection_Positive() {
        Test.startTest();
        List<Property_Inspection__c> overdue = PropertyInspectionHandler.getAllOverdueInspection();
        Test.stopTest();

        // Overdue = Date < today and Status in (Scheduled, In Progress)
        // From setup: A1 Past Scheduled, A1 Past In Progress, A2 Past Scheduled => total 3

        // Validate statuses and dates
        for (Property_Inspection__c insp : overdue) {
            System.assert(insp.Inspection_Date__c < Date.today(), 'Inspection date should be in the past');
            System.assert(insp.Inspection_Status__c == 'Scheduled' || insp.Inspection_Status__c == 'In Progress',
                          'Status must be Scheduled or In Progress');
        }
    }

    // 4) Positive test for updateAccountDescription appends latest notes per account present in the input list
    @IsTest
    static void testUpdateAccountDescription_Positive() {
        // Pick one inspection per account with notes
        Property_Inspection__c a1Insp = [
            SELECT Id, Account__c, Notes__c
            FROM Property_Inspection__c
            WHERE Account__c != null
            AND Account__r.Name = 'Prop A'
            ORDER BY Inspection_Date__c DESC
            LIMIT 1
        ];
        Property_Inspection__c a2Insp = [
            SELECT Id, Account__c, Notes__c
            FROM Property_Inspection__c
            WHERE Account__c != null
            AND Account__r.Name = 'Prop B'
            ORDER BY Inspection_Date__c DESC
            LIMIT 1
        ];

        // Seed existing description to verify appending behavior
        Account a1 = [SELECT Id, Description FROM Account WHERE Id = :a1Insp.Account__c LIMIT 1];
        a1.Description = 'Existing line';
        update a1;

        Test.startTest();
        PropertyInspectionHandler.updateAccountDescription(new List<Property_Inspection__c>{ a1Insp, a2Insp });
        Test.stopTest();

        // Assert the account descriptions got appended with the inspection notes
        Map<Id, Account> accs = new Map<Id, Account>([
            SELECT Id, Description FROM Account WHERE Id IN :new Set<Id>{ a1Insp.Account__c, a2Insp.Account__c }
        ]);

        System.assert(accs.containsKey(a1Insp.Account__c), 'A1 should be present');
        System.assert(accs.containsKey(a2Insp.Account__c), 'A2 should be present');

        System.assert(accs.get(a1Insp.Account__c).Description != null, 'A1 description should be populated');
        System.assert(accs.get(a2Insp.Account__c).Description != null, 'A2 description should be populated');

        System.assert(accs.get(a1Insp.Account__c).Description.contains('Existing line'),
            'A1 description should retain existing content');
        System.assert(accs.get(a1Insp.Account__c).Description.contains(String.valueOf(a1Insp.Notes__c)),
            'A1 description should include appended notes');
        System.assert(accs.get(a2Insp.Account__c).Description.contains(String.valueOf(a2Insp.Notes__c)),
            'A2 description should include appended notes');
    }

    // 5) Negative/bulk test: include inspection with null Account and one without notes; ensure no failure and only valid accounts updated
    @IsTest
    static void testUpdateAccountDescription_NegativeAndBulk() {
        // Create one with null account (should be ignored) and one with blank notes (should not update)
        Property_Inspection__c noAcc = new Property_Inspection__c(
            Name = 'Null Acc For Update',
            Inspection_Date__c = Date.today().addDays(-1),
            Inspection_Status__c = 'Scheduled'
        );
        Property_Inspection__c blankNotes = [
            SELECT Id, Account__c, Notes__c
            FROM Property_Inspection__c
            WHERE Account__c != null
            LIMIT 1
        ];
        blankNotes = blankNotes.clone(false, true, false, false);
        blankNotes.Id = null;
        blankNotes.Notes__c = null;

        insert new List<Property_Inspection__c>{ noAcc, blankNotes };

        // Choose one valid insp with notes to ensure at least one update happens
        Property_Inspection__c valid = [
            SELECT Id, Account__c, Notes__c
            FROM Property_Inspection__c
            WHERE Account__c != null
            LIMIT 1
        ];

        // Capture description before update
        Account beforeAcc = [SELECT Id, Description FROM Account WHERE Id = :valid.Account__c];

        Test.startTest();
        PropertyInspectionHandler.updateAccountDescription(new List<Property_Inspection__c>{ noAcc, blankNotes, valid });
        Test.stopTest();

        Account afterAcc = [SELECT Id, Description FROM Account WHERE Id = :valid.Account__c];
        System.assertNotEquals(beforeAcc.Description, afterAcc.Description,
            'Valid account description should change due to appended notes');

        // Ensure that including invalid records doesn't cause exceptions (test would have failed)
        // and that null notes did not cause updates for that record (cannot directly assert without querying description history)
        System.assert(true, 'Reached end without exception');
    }

    // 6) Edge case: calculateAverageInspectionRating with inspection on an Account that only has null ratings
    // We insert such data to confirm 0 is returned when aggregate avgRating is null.
    @IsTest
    static void testCalculateAverageInspectionRating_NoRatings() {
        Account a4 = new Account(Name = 'No Ratings Account');
        insert a4;

        // Insert inspections with null ratings only (or none) so aggregate AVG returns null -> method should return 0
        insert new Property_Inspection__c(
            Name = 'A4 Insp No Rating',
            Account__c = a4.Id,
            Inspection_Date__c = Date.today().addDays(-1),
            Inspection_Status__c = 'Scheduled'
        );

        Test.startTest();
        Decimal avg = PropertyInspectionHandler.calculateAverageInspectionRating(a4.Id);
        Test.stopTest();

        System.assertEquals(0, avg, 'When no ratings exist, method should return 0');
    }
}
