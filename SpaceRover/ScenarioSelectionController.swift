//
//  ScenarioSelectionController.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 7/16/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import CoreData
import UIKit

enum Scenario: Int {
  case RACE_CLASSIC = 0, RACE_RANDOM = 1;
}

extension Scenario {

  static func count() -> Int {
    return 2
  }

  func name() -> String {
    switch (self) {
    case .RACE_CLASSIC:
      return "Race - Classic Map"
    case .RACE_RANDOM:
      return "Race - Random Map"
    }
  }
}

class ScenarioSelectionController: UIViewController, UITableViewDataSource,
UIPickerViewDelegate, UIPickerViewDataSource {

  @IBOutlet weak var playerTable: UITableView!
  @IBOutlet weak var scenarioPicker: UIPickerView!
  var pickedScenario: Scenario = Scenario.RACE_CLASSIC

  override func viewDidLoad() {
    super.viewDidLoad()
    playerTable?.dataSource = self
    scenarioPicker?.delegate = self
    scenarioPicker?.dataSource = self
    loadPlayers()
  }

  lazy var context: NSManagedObjectContext? = {
    let delegate = UIApplication.shared.delegate as? AppDelegate
    return delegate?.persistentContainer.viewContext
  }()

  var players = [PlayerInfo]()

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let game = segue.destination as? GameViewController {
      print("Starting game")
      game.players = players
      game.randomMap = pickedScenario == Scenario.RACE_RANDOM
      game.state = GameState.NOT_STARTED
    }
  }

  @IBAction func startGame(_ sender: Any) {
    if players.count < 1 || players.count > 6 {
      let alert = UIAlertController(title:"Invalid number of players",
        message: "Please enter between 1 and 6 players", preferredStyle: .alert)
      let okayAction = UIAlertAction(title: "Okay", style: .cancel)
      alert.addAction(okayAction)
      present(alert, animated: true)
    } else {
      performSegue(withIdentifier: "startGame", sender: self)
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return players.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerListCell", for: indexPath)

    cell.textLabel?.text = players[indexPath.row].name
    cell.detailTextLabel?.text = players[indexPath.row].shipName
    let image = players[indexPath.row].color!.image().cgImage()
    cell.imageView?.image = UIImage(cgImage: image)

    return cell
  }

  @IBAction func addNewPlayer(sender: UIStoryboardSegue) {
    if let sourceController = sender.source as? PlayerEntryController,
      let player = sourceController.getPlayerInfo(context: context!) {

      player.turn = Int32(players.count)
      players.append(player)
      save(context: context!)
      
      let newIndexPath = IndexPath(row: players.count, section: 0)
      playerTable.insertRows(at: [newIndexPath], with: .automatic)
    }
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                 forRowAt indexPath: IndexPath) {

    if editingStyle == .delete {

      // remove the item from the data model
      let player = players[indexPath.row]
      context?.delete(player)
      players.remove(at: indexPath.row)
      var turn = 0
      for other in players {
        other.turn = Int32(turn)
        turn += 1
      }
      save(context: context!)

      // delete the table view row
      tableView.deleteRows(at: [indexPath], with: .fade)
    }
  }

  @IBAction func gameFinished(sender: UIStoryboardSegue) {
    // we don't really need to do anything here
  }

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return Scenario.count()
  }

  // The data to return for the row and component (column) that's being passed in
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                  forComponent component: Int) -> String? {
    return Scenario(rawValue: row)!.name()
  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    pickedScenario = Scenario(rawValue: row)!
  }

  func loadPlayers() {
    do {
      players = try context!.fetch(PlayerInfo.fetchRequest())
    } catch let error as NSError {
      fatalError("Error loading players: \(error), \(error.userInfo)")
    }
  }
}
