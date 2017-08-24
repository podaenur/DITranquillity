//
//  Helpers.swift
//  DITranquillity
//
//  Created by Alexander Ivlev on 14/06/16.
//  Copyright © 2016 Alexander Ivlev. All rights reserved.
//

import Foundation

////// Weak reference

class Weak {
  private(set) weak var value: AnyObject?
  
  init<T>(value: T) {
    self.value = value as AnyObject
  }
}


////// For remove optional type

protocol TypeGetter {
  static var type: DIAType { get }
}

extension ImplicitlyUnwrappedOptional: TypeGetter {
  static var type: DIAType { return Wrapped.self }
}

extension Optional: TypeGetter {
  static var type: DIAType { return Wrapped.self }
}

func removeTypeWrappers(_ type: Any.Type) -> Any.Type {
  if let typeGetter = type as? TypeGetter.Type {
    return removeTypeWrappers(typeGetter.type)
  }
  
  return type
}


////// For optional check

protocol IsOptional {}
extension Optional: IsOptional { }

func isOptional(_ type: Any.Type) -> Bool {
  return type is IsOptional.Type
}

////// For optional make

protocol OptionalMake {
  static func make(by obj: Any?) -> Self
}

extension Optional: OptionalMake {
  static func make(by obj: Any?) -> Optional<Wrapped> {
    if let typeObj = obj as? Wrapped {
      return typeObj
    }
    return nil
  }
}

extension DI.ByTag: OptionalMake {
  static func make(by obj: Any?) -> DI.ByTag<Tag, T> {
    return DI.ByTag<Tag, T>(object: gmake(by: obj) as T)
  }
}

extension DI.ByMany: OptionalMake {
  static func make(by obj: Any?) -> DI.ByMany<T> {
    return DI.ByMany<T>(objects: gmake(by: obj) as [T])
  }
}

func gmake<T>(by obj: Any?) -> T {
  if let opt = T.self as? OptionalMake.Type {
    return opt.make(by: obj) as! T // it's always valid
  }
  
  return obj as! T // can crash, but it's normally
}

////// For simple log

func description(type: DIAType) -> String {
  if let taggedType = type as? IsTag.Type {
    return "type: \(taggedType.type) with tag: \(taggedType.tag)"
  } else if let manyType = type as? IsMany.Type {
    return "many with type: \(manyType.type)"
  }
  return "type: \(type)"
}
