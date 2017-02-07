//
//  DIScanComponent.swift
//  DITranquillity
//
//  Created by Alexander Ivlev on 13/10/16.
//  Copyright © 2016 Alexander Ivlev. All rights reserved.
//

public class DIScanComponent: DIScanWithInitializer<DIScanned>, DIComponent {
  public func load(builder: DIContainerBuilder) {
    for component in getObjects().filter({ $0 is DIComponent }) {
      builder.register(component: component as! DIComponent)
    }
  }
}
