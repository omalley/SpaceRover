//
//  PlayerEntryController.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 7/23/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import CoreData
import UIKit

class PlayerEntryController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
  @IBOutlet weak var playerName: UITextField!
  @IBOutlet weak var shipName: UITextField!
  @IBOutlet weak var shipColor: UIPickerView!
  var pickedColor: SpaceshipColor = .blue

  override func viewDidLoad() {
    super.viewDidLoad()
    shipColor.dataSource = self
    shipColor.delegate = self
  }

  // The number of columns of data
  func numberOfComponents(in: UIPickerView) -> Int {
    return 1
  }

  // The number of rows of data
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return SpaceshipColor.count()
  }

  // The data to return for the row and component (column) that's being passed in
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return SpaceshipColor(rawValue: Int16(row))?.toString()
  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    pickedColor = SpaceshipColor(rawValue: Int16(row))!
  }

  @IBAction func savePlayer(_ sender: UIBarButtonItem) {
    print("savePlayer = \(String(describing: navigationController))")
    navigationController?.popViewController(animated: true)
  }

  @IBAction func cancelButton(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }

  func getPlayerInfo(context: NSManagedObjectContext) -> PlayerModel? {
    let result = PlayerModel(context: context)
    result.name = playerName.text
    let ship = ShipModel(context: context)
    ship.name = shipName.text
    ship.player = result
    result.color = pickedColor
    return result;
  }
}
