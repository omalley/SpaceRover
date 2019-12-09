//
//  ScenarioSelectionController.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 7/16/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import CoreData
import UIKit

class ScenarioSelectionController: UIViewController, UITableViewDataSource,
UIPickerViewDelegate, UIPickerViewDataSource {

  @IBOutlet weak var playerTable: UITableView!
  @IBOutlet weak var scenarioPicker: UIPickerView!
  var game: GameModel? = nil

  override func viewDidLoad() {
    super.viewDidLoad()
    playerTable?.dataSource = self
    scenarioPicker?.delegate = self
    scenarioPicker?.dataSource = self
    loadGame()
  }

  lazy var context: NSManagedObjectContext? = {
    let delegate = UIApplication.shared.delegate as? AppDelegate
    return delegate?.persistentContainer.viewContext
  }()

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let gameView = segue.destination as? GameViewController {
      print("Starting game")
      gameView.model = game
    }
  }

  @IBAction func startGame(_ sender: Any) {
    let playerCount = game!.players!.count
    if playerCount < 1 || playerCount > 6 {
      let alert = UIAlertController(title:"Invalid number of players",
        message: "Please enter between 1 and 6 players", preferredStyle: .alert)
      let okayAction = UIAlertAction(title: "Okay", style: .cancel)
      alert.addAction(okayAction)
      present(alert, animated: true)
    } else {
      game!.state = GameState.NOT_STARTED
      performSegue(withIdentifier: "startGame", sender: self)
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return game!.players!.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerListCell", for: indexPath)

    let player = game!.players?.array[indexPath.row] as! PlayerModel
    cell.textLabel?.text = player.name
    cell.detailTextLabel?.text = player.shipList[0].name
    let image = player.color!.image().cgImage()
    cell.imageView?.image = UIImage(cgImage: image)

    return cell
  }

  @IBAction func addNewPlayer(sender: UIStoryboardSegue) {
    if let sourceController = sender.source as? PlayerEntryController,
      let player = sourceController.getPlayerInfo(context: context!) {
      player.game = game
      save(context: context!)
      print("Printing \(game!.players!.count) players.")
      for player in game!.playerList {
        print("\(player.name!) is a player")
      }
      
      let newIndexPath = IndexPath(row: game!.players!.count - 1, section: 0)
      playerTable.insertRows(at: [newIndexPath], with: .automatic)
    }
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                 forRowAt indexPath: IndexPath) {

    if editingStyle == .delete {

      // remove the item from the data model
      let player = game!.players![indexPath.row] as! PlayerModel
      player.game = nil
      context?.delete(player)
      save(context: context!)

      // delete the table view row
      tableView.deleteRows(at: [indexPath], with: .fade)
    }
  }

  @IBAction func gameFinished(sender: UIStoryboardSegue) {
    game!.state = .NOT_STARTED
    save(context: context!)
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
    return Scenario(rawValue: Int16(row))!.name()
  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,
                  inComponent component: Int) {
    game!.scenario = Scenario(rawValue: Int16(row))!
  }

  func loadGame() {
    do {
      let gameList = try context!.fetch(GameModel.fetchRequest())
      if gameList.count >= 1 {
        game = gameList[0] as? GameModel
      } else {
        game = GameModel(context: context!)
        game!.scenario = .RACE_CLASSIC
        game!.state = .NOT_STARTED
      }
    } catch let error as NSError {
      fatalError("Error loading board: \(error), \(error.userInfo)")
    }
  }
}
