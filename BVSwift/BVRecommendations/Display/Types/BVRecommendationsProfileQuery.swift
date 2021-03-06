//
//
//  BVRecommendationsProfileQuery.swift
//  BVSwift
//
//  Copyright © 2018 Bazaarvoice. All rights reserved.
// 

import Foundation

/// Public class for handling BVRecommendationsProfile Queries
/// - Note:
/// \
/// For more information please see the
/// [Documentation].(https://developer.bazaarvoice.com/personalization-data-sdk)
public class BVRecommendationsProfileQuery:
BVRecommendationsQuery<BVRecommendationsProfile> {
  private var fields: [BVRecommendationsProfileField] = []
  
  public var productId: String? {
    for field in fields {
      if case let .product(id) = field {
        return id
      }
    }
    return nil
  }
  
  public var requiredCategory: String? {
    for field in fields {
      if case let .requiredCategory(category) = field {
        return category
      }
    }
    return nil
  }
  
  public init(_ limit: UInt16 = 20) {
    super.init(BVRecommendationsProfile.self)
  }
  
  final internal override
  var recommendationsPreflightResultsClosure: BVURLRequestablePreflightHandler? {
    return
      { [weak self ] (completion: BVCompletionWithErrorsHandler?) -> Void in
        
        guard let config = self?.configuration else {
          fatalError(
            "BVRecommendationsQuery requires configuration before it " +
            "can be issued.")
        }
        
        guard let fields = self?.fields else {
          let noFieldsErr =
            BVCommonError.unknown(
              "No fields for BVRecommendationsProfileQuery, or object has " +
              "been reaped early.")
          completion?(noFieldsErr)
          return
        }
        
        fields.forEach {
          switch $0 {
          case .preferredCategory:
            fallthrough
          case .requiredCategory:
            fallthrough
          case .product:
            let composed: String =
              [config.type.clientId, "\($0.representedValue)"]
                .joined(separator: "/").escaping()
            self?.update(.unsafe($0.description.escaping(), composed, nil))
          case .include:
            self?.add(.field($0, nil), coalesce: true)
            /*
             case .strategy:
             self.add(.field($0, nil), coalesce: true)
             */
          default:
            self?.update(.field($0, nil))
          }
        }
        
        completion?(nil)
    }
  }
}

// MARK: - BVRecommendationsProfileQuery: BVQueryFieldable
extension BVRecommendationsProfileQuery: BVQueryFieldable {
  public typealias Field = BVRecommendationsProfileField
  
  @discardableResult
  public func field(_ to: Field) -> Self {
    fields = fields.filter {
      switch to {
      case .include:
        return !($0 == to)
        /*
         case .strategy:
         return !($0 == to)
         */
      default:
        return !($0 % to)
      }
    }
    fields.append(to)
    return self
  }
}
