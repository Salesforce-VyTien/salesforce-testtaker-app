public with sharing class TT_HomePageController {
	
    // All Instance variables
    public Id testId{get; set;}
    public Id resultId{get; set;}

	private Testtaker_Test_Result__c newResult{get; set;}
	private List<Testtaker_Test_Question__c> allTestQuestionList{get; set;}
	private List<Testtaker_Test_Answer__c> allTestAnswersList{get; set;}
    private List<Testtaker_Test_Result_Detail__c> allTestResultDetailList{get; set;}


    public TT_HomePageController() {
    	allTestQuestionList = [
    		SELECT 
    			t.Total_Right_Answers__c, t.Total_Choices__c, t.Test__c, 
    			t.Question_Type__c, t.Name, t.Id, t.How_to_Score__c 
    		FROM 
    			Testtaker_Test_Question__c t
    	];	

    	allTestAnswersList = [
			SELECT 
				t.Test_Question__c, t.Name, t.Is_Correct__c, t.Id, 
				t.Answer__c 
			FROM 
				Testtaker_Test_Answer__c t
		];
    }



    // For Displaying Test
    public List<Testtaker_Test__c> getActiveTests(){
    	return [SELECT Id, Name FROM Testtaker_Test__c ];	
    }

    public List<Testtaker_Test_Result__c> getMyTests(){
    	return [SELECT Id, Name,Started__c,Completed__c,Test__r.Name FROM Testtaker_Test_Result__c WHERE Completed__c = null ];	
    }

    public List<Testtaker_Test_Result__c> getCompletedTests(){
    	return [SELECT Id, Name,Started__c,Completed__c,Test__r.Name FROM Testtaker_Test_Result__c WHERE Completed__c != null ORDER BY Completed__c DESC];	
    }

    // Navigation Functions

    public PageReference startNewTest(){
    	// This function will start up a new test depending on the id that is passed in
    	Testtaker_Test_Result__c newResult = new Testtaker_Test_Result__c();
    	newResult.Test__c = testId;
    	newResult.Started__c = datetime.now();
    	insert newResult;
    	resultId = newResult.Id;

    	generateTestInstance();

    	PageReference takeTestPage = Page.TT_TakeTest;
    	takeTestPage.getParameters().put('instanceId',newResult.Id);
    	return takeTestPage;
    }

    public PageReference resumeExistingTest(){
    	// This function will resume an existing test depending on the id that is passed in

    	PageReference takeTestPage = Page.TT_TakeTest;
    	takeTestPage.getParameters().put('instanceId',resultId);
    	return takeTestPage;
    }

    public PageReference viewCompletedTest(){
    	// This function will view a completed test depending on the id that is passed in

    	PageReference viewTestPage = Page.TT_ViewResults;
    	viewTestPage.getParameters().put('instanceId',resultId);
    	return viewTestPage;
    }



    // The following function deal with creating a test

    private Boolean generateTestInstance(){
    	// Get Test Questions
    	generateTestQuestions();
    	// Populate Answers
    	return true;
    }



    private Boolean generateTestQuestions(){
    	// Get the test data
    	Testtaker_Test__c mainTestData = [
    		SELECT 
    			t.Total_Questions__c, t.Name, t.Id 
    		FROM 
    			Testtaker_Test__c t
    		WHERE 
    			t.Id =: testId	
    		];

    	// Get all the questions

		List<Testtaker_Test_Question__c> allTestQuestions = new List<Testtaker_Test_Question__c>();
		for(Testtaker_Test_Question__c thisTestQuestion : allTestQuestionList){
			if(thisTestQuestion.Test__c == testId){
				allTestQuestions.add(thisTestQuestion);
			}
		}


    	// Create a map that will hold the test questions
    	Map<Id,Testtaker_Test_Question__c> testQuestionMap = new Map<Id,Testtaker_Test_Question__c>();

    	Integer tries = 0;

    	// Randomly add questions until the map is full
    	boolean doneAdding = false;
    	while(!doneAdding) {
    		Integer thisQuestionIndex = (Math.random()*allTestQuestions.size()).intValue();
    		if((testQuestionMap.size() >= mainTestData.Total_Questions__c) || (tries >= 500)){
    			doneAdding = true;
    		} else {
	    		if(!testQuestionMap.containsKey(allTestQuestions[thisQuestionIndex].Id)){
	    			testQuestionMap.put(allTestQuestions[thisQuestionIndex].Id,allTestQuestions[thisQuestionIndex]);
	    		}    			
    		}
    		tries = tries + 1;
    	}
    	// Now insert the map items into the database
    	Integer questionNumber = 1;
    	allTestResultDetailList = new List<Testtaker_Test_Result_Detail__c>();
    	for(Id keyId : testQuestionMap.keySet()){
    		Testtaker_Test_Result_Detail__c thisTestResultDetail = new Testtaker_Test_Result_Detail__c();
    		thisTestResultDetail.Question_Number__c = questionNumber;
    		thisTestResultDetail.Test_Question__c = keyId;
    		thisTestResultDetail.Test_Result__c = resultId;
    		allTestResultDetailList.add(thisTestResultDetail);
    		questionNumber = questionNumber + 1;
    	}
    	insert allTestResultDetailList;

    	for(Testtaker_Test_Result_Detail__c thisTestResultDetail : allTestResultDetailList){
			generateTestQuestionAnswers(thisTestResultDetail.Id,thisTestResultDetail.Test_Question__c);
    	}

    	return true;
    }
	


	private Boolean generateTestQuestionAnswers(Id testResultDetailId, Id testQuestionId){
		Boolean operationResult = true;
		

		// Get the Test Question Information
		Testtaker_Test_Question__c thisTestQuestion = new Testtaker_Test_Question__c();
		for(Testtaker_Test_Question__c currentTestQuestion : allTestQuestionList){
			if(currentTestQuestion.Id == testQuestionId){
				thisTestQuestion = currentTestQuestion;
			}
		}
		/* Marked for deletion
		Testtaker_Test_Question__c thisTestQuestion = [
			SELECT 
				t.Total_Right_Answers__c, t.Total_Choices__c, t.Short_Question__c, 
				t.Question_Type__c, t.Points_Per_Answer__c, t.Name, t.Maximum_Points__c, 
				t.Id, t.How_to_Score__c 
			FROM 
				Testtaker_Test_Question__c t
			WHERE 
				t.Id =: testQuestionId
		];
		*/
		
		// Get all right answers
		List<Testtaker_Test_Answer__c> allRightTestAnswers = new List<Testtaker_Test_Answer__c>();
		for(Testtaker_Test_Answer__c currentTestAnswer : allTestAnswersList){
			if((currentTestAnswer.Test_Question__c == thisTestQuestion.Id) && (currentTestAnswer.Is_Correct__c == true)){
				allRightTestAnswers.add(currentTestAnswer);	
			}
		}
		/*
		List<Testtaker_Test_Answer__c> allRightTestAnswers = [
			SELECT 
				t.Test_Question__c, t.Name, t.Is_Correct__c, t.Id, 
				t.Answer__c 
			FROM 
				Testtaker_Test_Answer__c t
			WHERE
				t.Test_Question__c =: thisTestQuestion.Id
			AND 
				t.Is_Correct__c = true
		];
		*/
		// Get all wrong answers
		List<Testtaker_Test_Answer__c> allWrongTestAnswers = new List<Testtaker_Test_Answer__c>();
		for(Testtaker_Test_Answer__c currentTestAnswer : allTestAnswersList){
			if((currentTestAnswer.Test_Question__c == thisTestQuestion.Id) && (currentTestAnswer.Is_Correct__c == false)){
				allWrongTestAnswers.add(currentTestAnswer);	
			}
		}
		/*
		List<Testtaker_Test_Answer__c> allWrongTestAnswers = [
			SELECT 
				t.Test_Question__c, t.Name, t.Is_Correct__c, t.Id, 
				t.Answer__c 
			FROM 
				Testtaker_Test_Answer__c t
			WHERE
				t.Test_Question__c =: thisTestQuestion.Id
			AND 
				t.Is_Correct__c = false
		];
		*/
		// Get the Result so we can fill it in

		Testtaker_Test_Result_Detail__c thisTestResultDetail = new Testtaker_Test_Result_Detail__c();
		for(Testtaker_Test_Result_Detail__c currentTestResultDetail : allTestResultDetailList){
			if(currentTestResultDetail.Id == testResultDetailId){
				thisTestResultDetail = currentTestResultDetail;
			}
		}
		/* Marked for deletion
		Testtaker_Test_Result_Detail__c thisTestResultDetail = [
			SELECT 
				t.Test_Result__c, t.Test_Question__c, t.Question_Number__c, 
				t.Possible_Answers__c, t.Name, t.Max_Score__c, t.Id, t.Correct_Answer__c  
			FROM 
				Testtaker_Test_Result_Detail__c t
			WHERE
				t.Id =: testResultDetailId
		];
		*/
    	boolean doneAdding = false;
    	Integer tries = 0;

		// Create a Map that will contain all possible answers
		Map<Id,Testtaker_Test_Answer__c> possibleAnswerMap = new Map<Id,Testtaker_Test_Answer__c>();
		if(allRightTestAnswers.size() > 0){
	    	// Randomly add correct answers until we reach the limit of correct answers
	    	while(!doneAdding) {
	    		Integer thisAnswerIndex = (Math.random()*allRightTestAnswers.size()).intValue();
	    		if((possibleAnswerMap.size() >= thisTestQuestion.Total_Right_Answers__c) || (tries >= 500)){
	    			doneAdding = true;
	    		} else {
		    		if(!possibleAnswerMap.containsKey(allRightTestAnswers[thisAnswerIndex].Id)){
		    			possibleAnswerMap.put(allRightTestAnswers[thisAnswerIndex].Id,allRightTestAnswers[thisAnswerIndex]);
		    		}    			
	    		}
	    		tries = tries + 1;
	    	}
			
		}

		if(allWrongTestAnswers.size() > 0){
	    	// Randomly add incorrect answers until we reach the limit of correct answers
	    	doneAdding = false;
	    	tries = 0;
	    	while(!doneAdding) {
	    		Integer thisAnswerIndex = (Math.random()*allWrongTestAnswers.size()).intValue();
	    		if((possibleAnswerMap.size() >= thisTestQuestion.Total_Choices__c) || (tries >= 500)){
	    			doneAdding = true;
	    		} else {
		    		if(!possibleAnswerMap.containsKey(allWrongTestAnswers[thisAnswerIndex].Id)){
		    			possibleAnswerMap.put(allWrongTestAnswers[thisAnswerIndex].Id,allWrongTestAnswers[thisAnswerIndex]);
		    		}    			
	    		}
	    		tries = tries + 1;
	    	}			
		}
		
		
		// Now shuffle the results
		Map<Id,Testtaker_Test_Answer__c> possibleRandomAnswerMap = new Map<Id,Testtaker_Test_Answer__c>();

    	doneAdding = false;
    	tries = 0;
    	List<Id> possibleAnswerList = new List<Id>();
    	possibleAnswerList.addAll(possibleAnswerMap.keySet());
    	
    	if(possibleAnswerMap.size() > 0){
	    	while(!doneAdding) {
	    		Integer thisAnswerIndex = (Math.random()*possibleAnswerMap.size()).intValue();
	    		Id thisAnswerKey = possibleAnswerList[thisAnswerIndex];
	    		 
	    		if((possibleRandomAnswerMap.size() >= possibleAnswerMap.size()) || (tries >= 500)){
	    			doneAdding = true;
	    		} else {
		    		if(!possibleRandomAnswerMap.containsKey(thisAnswerKey)){
		    			possibleRandomAnswerMap.put(thisAnswerKey,possibleAnswerMap.get(thisAnswerKey));
		    		}    			
	    		}
	    		tries = tries + 1;
	    	}
    	}
		
		String fullAnswerList = '';
		String fullChoicesList = ''; 
		
		// Loop through possibleRandomAswerMap and conver to lists
		for(Id p:possibleRandomAnswerMap.keySet()) {
			fullChoicesList += (fullChoicesList==''?'':',')+p;
			if(possibleRandomAnswerMap.get(p).Is_Correct__c == true){
				fullAnswerList += (fullAnswerList==''?'':',')+p;
			}
		}
		
		System.debug('possibleRandomAnswerMap = ' + possibleRandomAnswerMap);
		System.debug('fullAnswerList = ' + fullAnswerList);
		System.debug('fullChoicesList = ' + fullChoicesList);
		
		// Now update those two fields with the string
		thisTestResultDetail.Correct_Answer__c = fullAnswerList;
		thisTestResultDetail.Possible_Answers__c = fullChoicesList;
		update thisTestResultDetail;
		
		return operationResult;
	}


}