//
//
//  BVCommentSubmissionTest.swift
//  BVSwiftTests
//
//  Copyright © 2018 Bazaarvoice. All rights reserved.
// 

import XCTest
@testable import BVSwift

class BVCommentSubmissionTest: XCTestCase {
  
  private static var config: BVConversationsConfiguration =
  { () -> BVConversationsConfiguration in
    
    let analyticsConfig: BVAnalyticsConfiguration =
      .dryRun(
        configType: .staging(clientId: "conciergeapidocumentation"))
    
    return BVConversationsConfiguration.all(
      clientKey: "caB45h2jBqXFw1OE043qoMBD1gJC8EwFNCjktzgwncXY4",
      configType: .staging(clientId: "conciergeapidocumentation"),
      analyticsConfig: analyticsConfig)
  }()
  
  private static var privateSession:URLSession = {
    return URLSession(configuration: .default)
  }()
  
  override class func setUp() {
    super.setUp()
    
    BVPixel.skipAllPixelEvents = true
  }
  
  override class func tearDown() {
    super.tearDown()
    
    BVPixel.skipAllPixelEvents = false
  }
  
  func testSubmitReviewComment() {
    
    let expectation =
      self.expectation(description: "testSubmitReviewComment")
    
    let commentText = "Comment text Comment text Comment text Comment text"
    let commentTitle = "Comment title"
    let reviewId = "20134832"
    let randomId = String(arc4random_uniform(UInt32.max))
    
    let comment =
      BVComment(
        reviewId: reviewId,
        commentText: commentText,
        commentTitle: commentTitle)
    
    guard let commentSubmission = BVCommentSubmission(comment) else {
      XCTFail()
      expectation.fulfill()
      return
    }
    
    let usLocale: Locale = Locale(identifier: "en_US")
    
    (commentSubmission
      <+> .preview
      <+> .campaignId("BV_COMMENT_CAMPAIGN_ID")
      <+> .locale(usLocale)
      <+> .sendEmailWhenPublished(true)
      <+> .agree(true)
      <+> .nickname("UserNickname\(randomId)")
      <+> .identifier("UserId\(randomId)")
      <+> .email("developer@bazaarvoice.com"))
      .configure(BVCommentSubmissionTest.config)
      .handler { (response: BVConversationsSubmissionResponse<BVComment>) in
        
        if case let .failure(errors) = response {
          print(errors)
          XCTFail()
          expectation.fulfill()
          return
        }
        
        guard case let .success(meta, result) = response,
          let formFields = meta.formFields else {
            XCTFail()
            expectation.fulfill()
            return
        }
        
        XCTAssertEqual(meta.locale, usLocale.identifier)
        XCTAssertEqual(formFields.count, 11)
        XCTAssertEqual(result.title, commentTitle)
        XCTAssertEqual(result.commentText, commentText)
        XCTAssertNotNil(result.submissionTime)
        XCTAssertNil(result.submissionId)
        
        expectation.fulfill()
    }
    
    commentSubmission.async()
    
    self.waitForExpectations(timeout: 20) { (error) in
      XCTAssertNil(
        error, "Something went horribly wrong, request took too long.")
    }
  }
  
  func testSumbitCommentWithError() {
    
    let expectation =
      self.expectation(description: "testSumbitCommentWithError")
    
    let commentText = "short text"
    let reviewId = "12345"
    
    let comment = BVComment(reviewId: reviewId, commentText: commentText)
    
    guard let commentSubmission = BVCommentSubmission(comment) else {
      XCTFail()
      expectation.fulfill()
      return
    }
    
    (commentSubmission <+> .preview)
      .configure(BVCommentSubmissionTest.config)
      .handler { (response: BVConversationsSubmissionResponse<BVComment>) in
        
        if case let .failure(errors) = response,
          let error = errors.first {
          XCTAssertEqual(
            String(describing: error), "ERROR_PARAM_MISSING_USER_ID")
          expectation.fulfill()
          return
        }
        
        XCTFail()
        expectation.fulfill()
    }
    
    commentSubmission.async()
    
    self.waitForExpectations(timeout: 20) { (error) in
      XCTAssertNil(
        error, "Something went horribly wrong, request took too long.")
    }
  }
}
