public with sharing class TT_ReviewTestController {
	public TT_ReviewTestController() {
		// use the Instance Id
		testResultId = ApexPages.currentPage().getParameters().get('instanceId');
		
		String questionNumberString = ApexPages.currentPage().getParameters().get('questionNumber');

		system.debug('questionNumberString = ' + questionNumberString);

		
		if(questionNumberString != null){
			questionNumber = Integer.valueOf(questionNumberString);	
		} else {
			questionNumber = 0;
		}
		
		
		system.debug('questionNumber = ' + questionNumber);
		
		testResultQuery = [
			SELECT 
				t.Test__c, t.Started__c, t.Name, t.Id, t.Completed__c 
			FROM 
				Testtaker_Test_Result__c t
			WHERE
				Id=: testResultId	
		];
		
		testId = testResultQuery.Test__c;

		testHeader = [
			SELECT
				Name 
			FROM
				Testtaker_Test__c
			WHERE 
				Id =: testId
		];

		
		allQuestions = [
			SELECT 
				t.Test_Result__c, t.Test_Question__c, t.Supplied_Answer__c, 
				t.Question_Number__c, t.Possible_Answers__c, t.Name, 
				t.Max_Score__c, t.Id, t.Correct_Answer__c 
			FROM 
				Testtaker_Test_Result_Detail__c t
			WHERE 
				t.Test_Result__c =: testResultId 		
			ORDER BY
				Question_Number__c		
		];
		
		if(allQuestions.size() > 0){
			testResultDetailId = allQuestions[questionNumber].Id;
			
			testResultDetail = [
	    		SELECT 
					t.Test_Result__c, t.Test_Question__c, t.Supplied_Answer__c, 
					t.Question_Number__c, t.Possible_Answers__c, t.Name, 
					t.Max_Score__c, t.Id, t.Correct_Answer__c, t.Recorded_Score__c 
				FROM 
					Testtaker_Test_Result_Detail__c t
				WHERE 
					t.Id =: testResultDetailId
	    	];
			
			testAnswer = testResultDetail.Supplied_Answer__c;
			
			testQuestion = [
				SELECT 
					t.Total_Right_Answers__c, t.Total_Choices__c, t.Short_Question__c, 
					t.Question_Type__c, t.Points_Per_Answer__c, t.Name, 
					t.Maximum_Points__c, t.Long_Question__c, t.Id, t.How_to_Score__c 
				FROM 
					Testtaker_Test_Question__c t
				WHERE 
					t.Id =:  testResultDetail.Test_Question__c	
			];
			
			if(testResultDetail.Possible_Answers__c  != ''){
				testAnswers = [
					SELECT 
						t.Test_Question__c, t.Name, t.Is_Correct__c, t.Id, t.Answer__c 
					FROM 
						Testtaker_Test_Answer__c t
					WHERE 
						t.Test_Question__c =: testQuestion.Id	
				];
			}
			
			List<String> correctTestAnswerArray = new List<String>();
			if(testResultDetail.Correct_Answer__c != null){
				correctTestAnswerArray = testResultDetail.Correct_Answer__c.split(',');
			}

			correctTestAnswers = [
				SELECT 
					t.Test_Question__c, t.Name, t.Is_Correct__c, t.Id, t.Answer__c 
				FROM 
					Testtaker_Test_Answer__c t
				WHERE 
					t.Id IN : correctTestAnswerArray

			];

		}		
	}

    public List<SelectOption> getTestAnswerItems() {
        List<SelectOption> options = new List<SelectOption>();
        for (Testtaker_Test_Answer__c t : testAnswers){
        	options.add(new SelectOption(t.Id,t.Answer__c));
        }
        return options;
    }

	public Boolean getCanCompleteTest(){
		return questionNumber == (allQuestions.size() - 1);
	}

	public Boolean getHasNextQuestion(){
		return questionNumber < (allQuestions.size() - 1);
	}

	public Boolean getHasPreviousQuestion(){
		return questionNumber > 0;
	}

	public PageReference submitTestForGrading(){
    	PageReference homePagePage = new PageReference('/apex/TT_ViewResults?instanceID=' + testResultId);
    	homePagePage.setRedirect(true);
    	return homePagePage;
	}


	public PageReference goToNextPage(){
    	PageReference reviewTestPage = new PageReference('/apex/TT_ReviewTest?instanceID=' + testResultId + '&questionNumber=' + String.valueOf(questionNumber + 1));
    	reviewTestPage.setRedirect(true);
    	return reviewTestPage;
	}

	public PageReference goToPreviousPage(){
    	PageReference reviewTestPage = new PageReference('/apex/TT_ReviewTest?instanceID=' + testResultId + '&questionNumber=' + String.valueOf(questionNumber - 1));
    	reviewTestPage.setRedirect(true);
    	return reviewTestPage;
	}

	private void gradeQuestion(){
		Boolean anyErrors = false;
	
	}

	private List<Testtaker_Test_Result_Detail__c> allQuestions;
	private Testtaker_Test_Result__c testResultQuery{get; set;}
    private Id testId{get; set;}
    private Id testResultId{get; set;}
    private Id testResultDetailId{get; set;}    
	private Integer questionNumber{get; set;}
	public String testAnswer{get; set;}

	String[] testAnswerArray =  new String[]{};
	List<Testtaker_Test_Answer__c> correctTestAnswers =  new List<Testtaker_Test_Answer__c>();


    public Testtaker_Test_Question__c testQuestion{get;private set;}
    public Testtaker_Test_Result_Detail__c testResultDetail{get;private set;}
    public List<Testtaker_Test_Answer__c> testAnswers{get;private set;}
	public Testtaker_Test__c testHeader{get;private set;}

	public String[] getTestAnswerArray(){
		if(this.testAnswer != '' && this.testAnswer !=null){
			testAnswerArray = this.testAnswer.split(',');		
		} 
		else {
			testAnswerArray = new List<String>();	
		}
		
		return testAnswerArray;
		// return this.testAnswer.split(',');
	}

	public List<Testtaker_Test_Answer__c> getCorrectTestAnswers(){
		
		return correctTestAnswers;
		// return this.testAnswer.split(',');
	}

	public void setTestAnswerArray(String[] testAnswerArray){
	}



}