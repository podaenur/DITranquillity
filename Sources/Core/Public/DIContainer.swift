//
//  DIContainer.swift
//  DITranquillity
//
//  Created by Alexander Ivlev on 10/06/16.
//  Copyright © 2016 Alexander Ivlev. All rights reserved.
//

prefix operator *
/// Short syntax for resolve.
/// Using:
/// ```
/// let yourObj: YourClass = *container
/// ```
///
/// - Parameter container: A container.
/// - Returns: Created object.
public prefix func *<T>(container: DIContainer) -> T {
  return container.resolve()
}

/// A container holding all registered components,
/// allows you to register new components, parts, frameworks and
/// allows you to receive objects by type.
public final class DIContainer {
  public init() {
    resolver = Resolver(container: self)
    register{ [unowned self] in self }.lifetime(.prototype)
  }  
  
  internal let componentContainer = ComponentContainer()
  internal let bundleContainer = BundleContainer()
  internal private(set) var resolver: Resolver!
  
  // non thread safe!
  internal var includedParts: Set<String> = []
  internal var currentBundle: Bundle? = nil
}

// MARK: - register
public extension DIContainer {
  /// Registering a new component without initial.
  /// Using:
  /// ```
  /// container.register(YourClass.self)
  ///   . ...
  /// ```
  ///
  /// - Parameters:
  ///   - type: A type of new component.
  /// - Returns: component builder, to configure the component.
  @discardableResult
  public func register<Impl>(_ type: Impl.Type, file: String = #file, line: Int = #line) -> DIComponentBuilder<Impl> {
    return DIComponentBuilder(container: self, componentInfo: DIComponentInfo(type: Impl.self, file: file, line: line))
  }
  
  /// Declaring a new component with initial.
  /// In addition, container has a set of functions with a different number of parameters.
  /// Using:
  /// ```
  /// container.register(YourClass.init)
  /// ```
  /// OR
  /// ```
  /// container.register{ YourClass(p1: $0, p2: $1 as SpecificType, p3: $2) }
  /// ```
  ///
  /// - Parameter initial: initial method. Must return type declared at registration.
  /// - Returns: component builder, to configure the component.
  @discardableResult
  public func register<Impl>(file: String = #file, line: Int = #line, _ c: @escaping () -> Impl) -> DIComponentBuilder<Impl> {
    return register(file, line, MethodMaker.make(by: c))
  }
  
  
  internal func register<Impl>(_ file: String, _ line: Int, _ signature: MethodSignature) -> DIComponentBuilder<Impl> {
    let builder = register(Impl.self, file: file, line: line)
    builder.component.set(initial: signature)
    return builder
  }
}

// MARK: - resolve
public extension DIContainer {
  /// Resolve object by type.
  /// Can crash application, if can't found the type.
  /// But if the type is optional, then the application will not crash, but it returns nil.
  ///
  /// - Returns: Object for the specified type, or nil (see description).
  public func resolve<T>() -> T {
    return resolver.resolve()
  }
  
  /// Resolve object by type with tag.
  /// Can crash application, if can't found the type with tag.
  /// But if the type is optional, then the application will not crash, but it returns nil.
  ///
  /// - Parameter tag: Resolve tag.
  /// - Returns: Object for the specified type with tag, or nil (see description).
  public func resolve<T, Tag>(tag: Tag.Type) -> T {
    return by(tag: tag, on: resolver.resolve())
  }
  
  /// Resolve object by type with name.
  /// Can crash application, if can't found the type with name.
  /// But if the type is optional, then the application will not crash, but it returns nil.
  ///
  /// - Parameter name: Resolve name.
  /// - Returns: Object for the specified type with name, or nil (see description).
  public func resolve<T>(name: String) -> T {
    return resolver.resolve(name: name)
  }
  
  /// Resolve many objects by type.
  ///
  /// - Returns: Objects for the specified type.
  public func resolveMany<T>() -> [T] {
    return many(resolver.resolve())
  }
  
  /// Injected all dependencies into object.
  /// If the object type couldn't be found, then in logs there will be a warning, and nothing will happen.
  ///
  /// - Parameter object: object in which injections will be introduced.
  public func inject<T>(into object: T) {
    _ = resolver.injection(obj: object)
  }
  
  public func initializeSingletonObjects() {
    let singleComponents = componentContainer.components.filter{ .single == $0.lifeTime }
    
    if singleComponents.isEmpty { // for ignore log
      return
    }
    
    log(.info, msg: "Begin resolving \(singleComponents.count) singletons", brace: .begin)
    defer { log(.info, msg: "End resolving singletons", brace: .end) }
    
    for component in singleComponents {
      resolver.resolveSingleton(component: component)
    }
  }
}

// MARK: - Validation
public extension DIContainer {
  
  /// Validate the graph by checking various conditions. For faster performance, set false.
  /// - Returns: true if validation success.
  @discardableResult
  public func valid() -> Bool {
    let components = componentContainer.components
    return checkGraph(components) && checkGraphCycles(components)
  }
}


// MARK: - validate implementation
extension DIContainer {
  private func plog(_ parameter: MethodSignature.Parameter, msg: String) {
    let level: DILogLevel = parameter.optional ? .warning : .error
    log(level, msg: msg)
  }
  
  /// Check graph on presence of all necessary objects. That is, to reach the specified vertices from any vertex
  ///
  /// - Parameter resolver: resolver for use functions from him
  /// - Returns: true if graph is valid, false otherwire
  fileprivate func checkGraph(_ components: [Component]) -> Bool {
    var successfull: Bool = true
    
    for component in components {
      let parameters = component.signatures.flatMap{ $0.parameters }
      let bundle = component.bundle
      
      for parameter in parameters {
        if parameter.type is UseObject.Type {
          continue
        }
        
        let candidates = resolver.findComponents(by: parameter.type, with: parameter.name, from: bundle)
        let filtered = resolver.removeWhoDoesNotHaveInitialMethod(components: candidates)
        
        let correct = resolver.validate(components: filtered, for: parameter.type)
        let success = correct || parameter.optional
        successfull = successfull && success
        
        // Log
        if !correct {
          if candidates.isEmpty {
            plog(parameter, msg: "Not found component for \(description(type: parameter.type))")
          } else if filtered.isEmpty {
            let allPrototypes = !candidates.contains{ $0.lifeTime != .prototype }
            let infos = candidates.map{ $0.info }
            
            if allPrototypes {
              plog(parameter, msg: "Not found component for \(description(type: parameter.type)) that would have initialization methods. Were found: \(infos)")
            } else {
              log(.warning, msg: "Not found component for \(description(type: parameter.type)) that would have initialization methods, but object can maked from cache. Were found: \(infos)")
            }
          } else if filtered.count >= 1 {
            let infos = filtered.map{ $0.info }
            plog(parameter, msg: "Ambiguous \(description(type: parameter.type)) contains in: \(infos)")
          }
        }
      }
    }
    
    return successfull
  }
  
  fileprivate func checkGraphCycles(_ components: [Component]) -> Bool {
    var success: Bool = true
    
    typealias Stack = (component: Component, initial: Bool, cycle: Bool, many: Bool)
    func dfs(for component: Component, visited: Set<Component>, stack: [Stack]) {
      // it's cycle
      if visited.contains(component) {
        func isValidCycle() -> Bool {
          if stack.first!.component != component {
            // but inside -> will find in a another dfs call.
            return true
          }
          
          let components = stack.map{ $0.component.info }
          
          let allInitials = !stack.contains{ !($0.initial && !$0.many) }
          if allInitials {
            log(.error, msg: "You have a cycle: \(components) consisting entirely of initialization methods.")
            return false
          }
          
          let hasGap = stack.contains{ $0.cycle || ($0.initial && $0.many) }
          if !hasGap {
            log(.error, msg: "Cycle has no discontinuities. Please install at least one explosion in the cycle: \(components) using `injection(cycle: true) { ... }`")
            return false
          }
          
          let allPrototypes = !stack.contains{ $0.component.lifeTime != .prototype }
          if allPrototypes {
            log(.error, msg: "You cycle: \(components) consists only of object with lifetime - prototype. Please change at least one object lifetime to another.")
            return false
          }
          
          let containsPrototype = stack.contains{ $0.component.lifeTime == .prototype }
          if containsPrototype {
            log(.warning, msg: "You cycle: \(components) contains an object with lifetime - prototype. In some cases this can lead to an udesirable effect.")
          }
          
          return true
        }
        
        success = isValidCycle() && success
        return
      }
      
      let bundle = component.bundle
      
      var visited = visited
      visited.insert(component)
      
      
      func callDfs(by parameters: [MethodSignature.Parameter], initial: Bool, cycle: Bool) {
        for parameter in parameters {
          let many = parameter.many
          let candidates = resolver.findComponents(by: parameter.type, with: parameter.name, from: bundle)
          let filtered = resolver.removeWhoDoesNotHaveInitialMethod(components: candidates)
          
          for subcomponent in filtered {
            var stack = stack
            stack.append((subcomponent, initial, cycle, many))
            dfs(for: subcomponent, visited: visited, stack: stack)
          }
        }
      }
      
      if let initial = component.initial {
        callDfs(by: initial.parameters, initial: true, cycle: false)
      }
      
      for injection in component.injections {
        callDfs(by: injection.signature.parameters, initial: false, cycle: injection.cycle)
      }
    }
    
    
    for component in components {
      let stack = [(component, false, false, false)]
      dfs(for: component, visited: [], stack: stack)
    }
    
    return success
  }
}

extension Component {
  fileprivate var signatures: [MethodSignature] {
    var result: [MethodSignature] = []
    
    if let initial = self.initial {
      result.append(initial)
    }
    
    for injection in injections {
      result.append(injection.signature)
    }
    
    return result
  }
}
