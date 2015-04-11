public with sharing class TT_TakeTestController {
    public TT_TakeTestController() {
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
		system.debug('Zo : testAnswer = ' + testAnswer);
		testResultDetail.Supplied_Answer__c = testAnswer;
		gradeQuestion();
		update testResultDetail;
		
		testResultQuery.Completed__c = DateTime.now();
		update testResultQuery;
		
    	// PageReference homePagePage = Page.TT_HomePage;
    	PageReference homePagePage = new PageReference('/apex/TT_ViewResults?instanceID=' + testResultId);

    	homePagePage.setRedirect(true);
    	return homePagePage;
		
		
	}


	public PageReference goToNextPage(){
		system.debug('Zo : testAnswer = ' + testAnswer);
		testResultDetail.Supplied_Answer__c = testAnswer;
		gradeQuestion();
		update testResultDetail;
		
    	// PageReference takeTestPage = Page.TT_TakeTest;
    	PageReference takeTestPage = new PageReference('/apex/TT_TakeTest?instanceID=' + testResultId + '&questionNumber=' + String.valueOf(questionNumber + 1));
    	// takeTestPage.getParameters().put('instanceId',testResultId);
    	// takeTestPage.getParameters().put('questionNumber',String.valueOf(questionNumber + 1));
    	takeTestPage.setRedirect(true);
    	return takeTestPage;
		
		
	}

	public PageReference goToPreviousPage(){
		system.debug('Zo : testAnswer = ' + testAnswer);
		testResultDetail.Supplied_Answer__c = testAnswer;
		gradeQuestion();
		update testResultDetail;
		
    	// PageReference takeTestPage = Page.TT_TakeTest;
    	PageReference takeTestPage = new PageReference('/apex/TT_TakeTest?instanceID=' + testResultId + '&questionNumber=' + String.valueOf(questionNumber - 1));
    	// takeTestPage.getParameters().put('instanceId',testResultId);
    	// takeTestPage.getParameters().put('questionNumber',String.valueOf(questionNumber - 1));
    	takeTestPage.setRedirect(true);
    	return takeTestPage;
				
	}

	private void gradeQuestion(){
		Boolean anyErrors = false;
		Integer maxScore = 0;
		Integer recordedScore = 0;
		Integer partialScore = 0;


		List<String> suppliedAnswerArray = new List<String>();
		List<String> correctAnswerArray = new List<String>();
		Set<String> suppliedAnswerSet = new Set<String>();
		Set<String> correctAnswerSet = new Set<String>();



		// testResultDetail
			// t.Test_Result__c, t.Test_Question__c, t.Supplied_Answer__c, 
			// t.Question_Number__c, t.Possible_Answers__c, t.Name, 
			// t.Max_Score__c, t.Id, t.Correct_Answer__c, t.Recorded_Score__c 

		// testQuestion
			// t.Total_Right_Answers__c, t.Total_Choices__c, t.Short_Question__c, 
			// t.Question_Type__c, t.Points_Per_Answer__c, t.Name, 
			// t.Maximum_Points__c, t.Long_Question__c, t.Id, t.How_to_Score__c

		maxScore = testQuestion.Maximum_Points__c.intValue();
		partialScore = testQuestion.Points_Per_Answer__c.intValue();

		// if the question type is single select
		if((testQuestion.Question_Type__c == 'Single Select') || (testQuestion.Question_Type__c == 'Multiple Choice')){
			// Check to see if supplied answer matches the correct answer and score max answer
			if(testResultDetail.Supplied_Answer__c != null){
				suppliedAnswerArray = testResultDetail.Supplied_Answer__c.split(',');	
			}
			if(testResultDetail.Correct_Answer__c != null){
				correctAnswerArray = testResultDetail.Correct_Answer__c.split(',');	
			}
			suppliedAnswerSet.addAll(suppliedAnswerArray);
			correctAnswerSet.addAll(correctAnswerArray);
			if((suppliedAnswerArray != null) && (correctAnswerArray != null)){
				// we need to actually tally the results
				// loop through each right answer and see if we chose it and add each to score
				for(String suppliedAnswer : suppliedAnswerArray){
					if(correctAnswerSet.contains(suppliedAnswer)){
						recordedScore += partialScore;
					} else {
						anyErrors = true;
					}
				}
			} 
			else {
				if((correctAnswerArray == null)){
					// If correct answer null then give them full credit
					recordedScore = maxScore;
				} 
				else { // One or the other is null so you fail
					recordedScore = 0;
					anyErrors = true;
				}
			}
		}
		
		// If the question type is Text Answer or Essay
		if((testQuestion.Question_Type__c == 'Text Answer') || (testQuestion.Question_Type__c == 'Essay Answer')){
			// 	Check to see if the text equals the answer give credit for exact match
			if((testResultDetail.Supplied_Answer__c != null) && (testResultDetail.Correct_Answer__c != null)){
				if(testResultDetail.Supplied_Answer__c.trim() == testResultDetail.Correct_Answer__c.trim()){
					testResultDetail.Recorded_Score__c = maxScore;
					testResultDetail.Max_Score__c = maxScore;
				}
				else {
					testResultDetail.Recorded_Score__c = 0;
					testResultDetail.Max_Score__c = maxScore;
				}
			}
			else {
				if(testResultDetail.Supplied_Answer__c == null){
					testResultDetail.Recorded_Score__c = 0;
					testResultDetail.Max_Score__c = maxScore;
				}
				else {
					testResultDetail.Recorded_Score__c = maxScore;
					testResultDetail.Max_Score__c = maxScore;
				}	
			}
		}

		

		// Scoring

		// 	How to score - all or nothing . Give full if no errors and 0 if any
		if(testQuestion.How_to_Score__c == 'All or Nothing'){
			if(anyErrors){
				testResultDetail.Recorded_Score__c = 0;
				testResultDetail.Max_Score__c = maxScore;
			}
			else{
				testResultDetail.Recorded_Score__c = maxScore;
				testResultDetail.Max_Score__c = maxScore;
			}
		}
		// 	How to score - Allow partial scoring - record partial score 
		if(testQuestion.How_to_Score__c == 'Allow partial scoring'){
			if(anyErrors){
				testResultDetail.Recorded_Score__c = 0;
				testResultDetail.Max_Score__c = maxScore;
			}
			else{
				testResultDetail.Recorded_Score__c = recordedScore;
				testResultDetail.Max_Score__c = maxScore;
			}
		}
		//  How to score - Don't score - Score 0 for both recorded score and max score
		if(testQuestion.How_to_Score__c == 'Don\'t score'){
				testResultDetail.Recorded_Score__c = 0;
				testResultDetail.Max_Score__c = 0;
		}
	
	}


	
	
	private List<Testtaker_Test_Result_Detail__c> allQuestions;
	private Testtaker_Test_Result__c testResultQuery{get; set;}
    private Id testId{get; set;}
    private Id testResultId{get; set;}
    private Id testResultDetailId{get; set;}    
	private Integer questionNumber{get; set;}
	public String testAnswer{get; set;}

	String[] testAnswerArray =  new String[]{};

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

	public void setTestAnswerArray(String[] testAnswerArray){
		this.testAnswerArray = testAnswerArray; 
		this.testAnswer = '';
		for(String thisAnswer : testAnswerArray){
			if(this.testAnswer == ''){
				this.testAnswer += thisAnswer;
			} else {
				this.testAnswer += ',' + thisAnswer;
			}
		}
	}




}