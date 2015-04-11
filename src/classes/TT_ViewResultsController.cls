public with sharing class TT_ViewResultsController {
	public TT_ViewResultsController() {
		testResultId = ApexPages.currentPage().getParameters().get('instanceId');

		testResultQuery = [
			SELECT 
				t.Test__c, t.Started__c, t.Name, t.Id, t.Completed__c 
			FROM 
				Testtaker_Test_Result__c t
			WHERE
				Id=: testResultId	
		];
		
		testId = testResultQuery.Test__c;
		
		allTestResultDetails = [
			SELECT 
				t.Test_Result__c, t.Test_Question__c, 
				t.Test_Question__r.Name, t.Test_Question__r.Short_Question__c, t.Supplied_Answer__c, 
				t.Question_Number__c, t.Possible_Answers__c, t.Name, 
				t.Max_Score__c, t.Id, t.Correct_Answer__c, t.Recorded_Score__c  
			FROM 
				Testtaker_Test_Result_Detail__c t
			WHERE 
				t.Test_Result__c =: testResultId 		
			ORDER BY
				Question_Number__c		
		];

		allTestQuestions = [
			SELECT 
				t.Total_Right_Answers__c, t.Total_Choices__c, t.Test__c, t.Short_Question__c, 
				t.Question_Type__c, t.Points_Per_Answer__c, t.Name, t.Maximum_Points__c, 
				t.Long_Question__c, t.Id, t.How_to_Score__c 
			FROM 
				Testtaker_Test_Question__c t
			WHERE
				t.Test__c =: testResultQuery.Test__c
		];
		
		allTestAnswers = [
			SELECT 
				t.Test_Question__c, t.Name, t.Is_Correct__c, t.Id, t.Answer__c 
			FROM 
				Testtaker_Test_Answer__c t
			WHERE 
				t.Test_Question__r.Test__c =: testResultQuery.Test__c	
		];


		maximumTestPoints = 0;
		recordedTestPoints = 0;
		finalTestScore = 0;
		// finalTestScore.setScale(2);

		for(Testtaker_Test_Result_Detail__c testResultDetail : allTestResultDetails){
			if(testResultDetail.Max_Score__c != null){
				maximumTestPoints += testResultDetail.Max_Score__c;
			}
			if(testResultDetail.Recorded_Score__c != null){
				recordedTestPoints += testResultDetail.Recorded_Score__c;
			}
			
		}

		if(maximumTestPoints > 0){
			finalTestScore = (recordedTestPoints/maximumTestPoints) * 100;
		}

	}

	public PageReference deleteTest(){
		delete testResultQuery;
    	PageReference homePage = new PageReference('/apex/TT_HomePage');
    	homePage.setRedirect(true);
    	return homePage;		
	}

    public PageReference viewTestResult(){
    	// This function will resume an existing test depending on the id that is passed in

    	PageReference viewResultPage = Page.TT_ReviewTest;
    	viewResultPage.getParameters().put('instanceId',testResultId);
    	return viewResultPage;
    }


    // public Id resultId{get; set;}

	private Id testResultId{get; set;}

	private Testtaker_Test_Result__c testResultQuery{get; set;}
	public List<Testtaker_Test_Result_Detail__c> allTestResultDetails{get;private set;}

    private Id testId{get; set;}
    private Id testResultDetailId{get; set;}    

    public List<Testtaker_Test_Question__c> allTestQuestions{get;private set;}
    public List<Testtaker_Test_Answer__c> allTestAnswers{get;private set;}

    public Decimal maximumTestPoints{get;set;} 
    public Decimal recordedTestPoints{get;set;} 
    public Decimal finalTestScore{get;set;} 


}