public with sharing class PropertyInspectionHandler {
    public static Decimal calculateAverageInspectionRating(Id accountId){
        Decimal avgRating;
        if(accountId == null){
            return 0;
        }
        AggregateResult aggregateResult = [SELECT AVG(Overall_Rating__c) avgRating FROM Property_Inspection__c WHERE Account__c = :accountId];
        Decimal avgRatingGet = (Decimal) aggregateResult.get('avgRating');
        if(avgRatingGet != null){
            avgRating = avgRatingGet.setScale(2);
        } else {
            avgRating = 0;
        }
        return avgRating;
    }

    public static void updateAccountDescription(list<Property_Inspection__c> propertyInspectionList){
        Set<Id> accountIds = new Set<Id>();
        for(Property_Inspection__c inspection : propertyInspectionList){
            if(inspection.Account__c != null){
                accountIds.add(inspection.Account__c);
            }
        }
        
        List<Account> accountsToUpdate = new List<Account>();
        for(Account acc : [SELECT Id, Description FROM Account WHERE Id IN :accountIds]){
            for(Property_Inspection__c inspection : propertyInspectionList){
                if(inspection.Account__c == acc.Id && inspection.Notes__c != null){
                    String newDescription = (acc.Description != null ? acc.Description + '\n' : '') + inspection.Notes__c;
                    acc.Description = newDescription;
                    accountsToUpdate.add(acc);
                }
            }
        }
        if(!accountsToUpdate.isEmpty()){
            update accountsToUpdate;
        }
    }

    public static List<Property_Inspection__c> getAllOverdueInspection(){
        return [SELECT Id, Name, Overall_Rating__c, Inspection_Date__c, Inspection_Status__c, Notes__c, Account__c 
                FROM Property_Inspection__c 
                WHERE Inspection_Date__c < :Date.today() AND Inspection_Status__c IN ('Scheduled', 'In Progress')];
    }
}