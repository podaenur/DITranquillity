//
//  DITranquillityTests_Resolve.swift
//  DITranquillityTest
//
//  Created by Alexander Ivlev on 15/07/16.
//  Copyright © 2016 Alexander Ivlev. All rights reserved.
//

import XCTest
import DITranquillity


class DITranquillityTests_Resolve: XCTestCase {
  override func setUp() {
    super.setUp()
  }

  func test01_ResolveByClass() {
    let container = DIContainer()
    
    container.register(FooService.init)
    
    let service_auto: FooService = container.resolve()
    XCTAssertEqual(service_auto.foo(), "foo")
    
    let service_fast: FooService = *container
    XCTAssertEqual(service_fast.foo(), "foo")
  }
  
  func test02_ResolveByProtocol() {
    let container = DIContainer()
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self){$0}
    
    let service_auto: ServiceProtocol = container.resolve()
    XCTAssertEqual(service_auto.foo(), "foo")
    
    let service_fast: ServiceProtocol = *container
    XCTAssertEqual(service_fast.foo(), "foo")
  }
  
  func test03_ResolveByClassAndProtocol() {
    let container = DIContainer()
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self){$0}
    
    let service_protocol: ServiceProtocol = *container
    XCTAssertEqual(service_protocol.foo(), "foo")
    
    let service_class: FooService = *container
    XCTAssertEqual(service_class.foo(), "foo")
  }
  
  func test04_ResolveWithInitializerResolve() {
    let container = DIContainer()
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self){$0}
    
    container.register(Inject.init)
    
    let inject: Inject = *container
    XCTAssertEqual(inject.service.foo(), "foo")
  }
  
  func test05_ResolveWithDependencyResolveOpt() {
    let container = DIContainer()
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self){$0}
    
    container.register(InjectOpt.init)
      .injection { $0.service = $1 }
    
    let inject: InjectOpt = *container
    XCTAssertEqual(inject.service!.foo(), "foo")
  }
  
  func test06_ResolveWithDependencyResolveOptNil() {
    let container = DIContainer()
    
    container.register(InjectOpt.init)
      .injection { $0.service = $1 }
    
    let inject: InjectOpt = *container
    XCTAssert(nil == inject.service)
  }
  
  
  func test07_ResolveWithDependencyResolveImplicitly() {
    let container = DIContainer()
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self){$0}
    
    container.register(InjectImplicitly.init)
      .injection { $0.service = $1 }
    
    let inject: InjectImplicitly = *container
    XCTAssertEqual(inject.service.foo(), "foo")
  }
  
  func test08_ResolveMultiplyWithDefault() {
    let container = DIContainer()
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self){$0}
      .default()
    
    container.register(BarService.init)
      .as(check: ServiceProtocol.self){$0}
    
    let service: ServiceProtocol = *container
    XCTAssertEqual(service.foo(), "foo")
  }
  
  func test09_ResolveMultiplyWithDefault_Reverse() {
    let container = DIContainer()
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self){$0}
    
    container.register(BarService.init)
      .as(check: ServiceProtocol.self){$0}
      .default()
    
    let service: ServiceProtocol = *container
    XCTAssertEqual(service.foo(), "bar")
  }
  
  func test10_ResolveMultiplyByName() {
    let container = DIContainer()
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self, name: "foo"){$0}
      .lifetime(.single)
    
    container.register(BarService.init)
      .as(check: ServiceProtocol.self, name: "bar"){$0}
      .lifetime(.single)
    
    let serviceFoo: ServiceProtocol = container.resolve(name: "foo")
    XCTAssertEqual(serviceFoo.foo(), "foo")
    
    let serviceBar: ServiceProtocol = container.resolve(name: "bar")
    XCTAssertEqual(serviceBar.foo(), "bar")
    
    XCTAssertNotEqual(Unmanaged.passUnretained(serviceFoo as AnyObject).toOpaque(), Unmanaged.passUnretained(serviceBar as AnyObject).toOpaque())
  }
  
  func test10_ResolveMultiplyByTag() {
    let container = DIContainer()
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self, tag: FooService.self){$0}
      .lifetime(.single)
    
    container.register(BarService.init)
      .as(check: ServiceProtocol.self, tag: BarService.self){$0}
      .lifetime(.single)
    
    let serviceFoo: ServiceProtocol = container.resolve(tag: FooService.self)
    XCTAssertEqual(serviceFoo.foo(), "foo")
    
    let serviceBar: ServiceProtocol = container.resolve(tag: BarService.self)
    XCTAssertEqual(serviceBar.foo(), "bar")
    
    XCTAssertNotEqual(Unmanaged.passUnretained(serviceFoo as AnyObject).toOpaque(), Unmanaged.passUnretained(serviceBar as AnyObject).toOpaque())
  }
  
  func test11_ResolveMultiplySingleByName() {
    let container = DIContainer()
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self, name: "foo"){$0}
      .as(check: ServiceProtocol.self, name: "bar"){$0}
      .lifetime(.single)
    
    let serviceFoo: ServiceProtocol = container.resolve(name: "foo")
    XCTAssertEqual(serviceFoo.foo(), "foo")
    
    let serviceFoo2: ServiceProtocol = container.resolve(name: "bar")
    XCTAssertEqual(serviceFoo2.foo(), "foo")
    
    XCTAssertEqual(Unmanaged.passUnretained(serviceFoo as AnyObject).toOpaque(), Unmanaged.passUnretained(serviceFoo2 as AnyObject).toOpaque())
  }
  
  func test11_ResolveMultiplySingleByTag() {
    let container = DIContainer()
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self, tag: FooService.self){$0}
      .as(check: ServiceProtocol.self, tag: BarService.self){$0}
      .lifetime(.single)
    
    let serviceFoo: ServiceProtocol = by(tag: FooService.self, on: *container)
    XCTAssertEqual(serviceFoo.foo(), "foo")
    
    let serviceFoo2: ServiceProtocol = container.resolve(tag: BarService.self)
    XCTAssertEqual(serviceFoo2.foo(), "foo")
    
    XCTAssertEqual(Unmanaged.passUnretained(serviceFoo as AnyObject).toOpaque(), Unmanaged.passUnretained(serviceFoo2 as AnyObject).toOpaque())
  }
  
  func test12_ResolveMultiplyMany() {
    let container = DIContainer()
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self){$0}
    
    container.register(BarService.init)
      .as(check: ServiceProtocol.self){$0}
    
    let services: [ServiceProtocol] = container.resolveMany()
    XCTAssertEqual(services.count, 2)
    XCTAssertNotEqual(services[0].foo(), services[1].foo())
  }
  
  func test13_ResolveCircular2() {
    let container = DIContainer()
    
    container.register(Circular2A.init)
      .lifetime(.objectGraph)
    
    container.register(Circular2B.init)
      .lifetime(.objectGraph)
      .injection(cycle: true) { $0.a = $1 }
    
    let a: Circular2A = *container
    XCTAssert(a === a.b.a)
    XCTAssert(a.b === a.b.a.b)
    
    let b: Circular2B = *container
    XCTAssert(b === b.a.b)
    XCTAssert(b.a === b.a.b.a)
    
    XCTAssert(a !== b.a)
    XCTAssert(a.b !== b)
  }
  
  func test14_ResolveCircular3() {
    let container = DIContainer()
    
    container.register(Circular3A.init)
      .lifetime(.objectGraph)
    
    container.register(Circular3B.init)
      .lifetime(.objectGraph)
    
    container.register(Circular3C.init)
      .lifetime(.objectGraph)
      .injection(cycle: true) { c, a in c.a = a }
    
    let a: Circular3A = *container
    XCTAssert(a === a.b.c.a)
    XCTAssert(a.b === a.b.c.a.b)
    XCTAssert(a.b.c === a.b.c.a.b.c)
    
    let b: Circular3B = *container
    XCTAssert(b === b.c.a.b)
    XCTAssert(b.c === b.c.a.b.c)
    XCTAssert(b.c.a === b.c.a.b.c.a)
    
    let c: Circular3C = *container
    XCTAssert(c === c.a.b.c)
    XCTAssert(c.a === c.a.b.c.a)
    XCTAssert(c.a.b === c.a.b.c.a.b)
    
    XCTAssert(a.b !== b)
    XCTAssert(a.b.c !== c)
    
    XCTAssert(b.c !== c)
    XCTAssert(b.c.a !== a)
    
    XCTAssert(c.a !== a)
    XCTAssert(c.a.b !== b)
  }
  
  func test15_ResolveCircularDouble2A() {
    let container = DIContainer()
    
    container.register(CircularDouble2A.init)
      .lifetime(.objectGraph)
      .injection(cycle: true) { $0.b1 = $1 }
      .injection(cycle: true) { a, b2 in a.b2 = b2 }
    
    container.register(CircularDouble2B.init)
      .lifetime(.prototype)
    
    //b1 !== b2 because prototype
    let a: CircularDouble2A = *container
    XCTAssert(a.b1 !== a.b2)
    XCTAssert(a === a.b1.a)
    XCTAssert(a.b1 === a.b1.a.b1)
    XCTAssert(a === a.b2.a)
    XCTAssert(a.b2 === a.b2.a.b2)
  }
  
  func test15_ResolveCircularDouble2B() {
    let container = DIContainer()
    
    container.register(CircularDouble2A.init)
      .lifetime(.objectGraph)
      .injection(cycle: true) { $0.b1 = $1 }
      .injection(cycle: true) { a, b2 in a.b2 = b2 }
    
    container.register(CircularDouble2B.init)
      .lifetime(.objectGraph)
    
    //!!! b1 === b2 === b because objectGraph
    let b: CircularDouble2B = *container
    XCTAssert(b === b.a.b1)
    XCTAssert(b === b.a.b2)
    XCTAssert(b.a === b.a.b1.a)
    XCTAssert(b.a === b.a.b2.a)
  }
  
  func test16_ResolveCircularDoubleOneDependency2_WithoutCycle() {
    let container = DIContainer()
    
    container.register(CircularDouble2A.init)
      .lifetime(.objectGraph)
      .injection{ $0.set(b1: $1, b2: $2) }

    
    container.register(CircularDouble2B.init)
      .lifetime(.objectGraph)
    
    XCTAssert(!container.valid())
  }
  
  func test17_DependencyIntoDependency() {
    let container = DIContainer()
    
    container.register(DependencyA.init)
    
    container.register(DependencyB.init)
      .injection { $0.a = $1 }
    
    container.register(DependencyC.init)
      .injection { $0.b = $1 }
    
    let c: DependencyC = *container
    
    XCTAssert(c.b != nil)
    XCTAssert(c.b.a != nil)
  }
  
  func test18_ResolveManyWithNamesTags() {
    let container = DIContainer()
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self){$0}
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self, tag: FooService.self){$0}
    
    container.register(BarService.init)
      .as(check: ServiceProtocol.self, tag: BarService.self){$0}
    
    container.register(FooService.init)
      .as(check: ServiceProtocol.self, name: "foo test"){$0}
    
    container.register(BarService.init)
      .as(check: ServiceProtocol.self, name: "bar test"){$0}
    
    let services: [ServiceProtocol] = many(*container)
    XCTAssertEqual(services.count, 5)
    
  }
}

