//
//  ViewController.swift
//  SampleChaos
//
//  Created by Alexander Ivlev on 09/06/16.
//  Copyright © 2016 Alexander Ivlev. All rights reserved.
//

import UIKit
import DITranquillity

class ViewController: UIViewController {
  internal var container: DIContainer!
  
  internal var injectGlobal: Inject?
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let vc1_1: UIView = container.resolve()
    print("Create VC1_1: \(vc1_1)")
    
    let vc1_2: UIView = *container
    print("Create VC1_2: \(vc1_2)")
    
    let vc2_2: UIAppearance = container.resolve()
    print("Create VC2_2: \(vc2_2)")
    
    
    let inject1: Inject = *container
    print("Create Inject1: \(inject1.description)")
    
    let injectMany: InjectMany = *container
    print("Create injectMany: \(injectMany)")
    
    
    print("Create injectGlobal: \(injectGlobal)")
    
    //Animals
    
    let cat = (*container as DI.ByTag<CatTag, Animal>).object
    let dog = (*container as DI.ByTag<DogTag, Animal>).object
    let bear = (*container as DI.ByTag<BearTag, Animal>).object
    
    let defaultAnimal: Animal = *container
    
    print("Cat: \(cat.name) Dog: \(dog.name) Bear: \(bear.name) Default(Dog): \(defaultAnimal.name)")
    
    //Circular
    let circularT1: Circular1 = *container
    let circularT2: Circular2 = *container
    
    print("Circular test 1: \(circularT1.description) + \(circularT1.ref.description)")
    print("Circular test 2: \(circularT2.description) + \(circularT2.ref.description)")
    
  }
}

