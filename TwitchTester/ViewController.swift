//
//  ViewController.swift
//  TwitchTester
//
//  Created by Jakob Cederlund on 2015-09-04.
//  Copyright (c) 2015 dev4phone. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!

    let CellName = "TableViewCell"

    let gamesURL = "https://api.twitch.tv/kraken/games/top"

    // om denna är satt så läses alla logo-bilder in direkt
    // (annars så läses de in när de blir synliga)
    let getAllLogos = false

    // MARK: - viewDidLoad och HTTP-request
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: CellName, bundle: nil), forCellReuseIdentifier: CellName)
        Alamofire.request(.GET, gamesURL,
            parameters: nil, encoding: .URL,
            headers: ["Accept": "application/vnd.twitchtv.v3+json"])
            .responseJSON { request, response, json, error in
                if error == nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.reloadWithData(JSON(json!))
                    }
                }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        imageCache = [:]
    }

    // MARK: - UITableViewDataSource

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellName, forIndexPath: indexPath) as! TableViewCell
        let game = games[indexPath.row]
        if let image = imageCache[game.logoURL] {
            cell.logoImageView.image = image
        } else {
            cell.logoImageView.image = nil
            if !getAllLogos {
                Alamofire.request(.GET, game.logoURL).response { _, _, data, _ in
                    if data != nil {
                        let image = UIImage(data: data!)
                        self.imageCache[game.logoURL] = image
                        cell.logoImageView.image = image
                    }
                }
            }
        }
        cell.numChannelsLabel.text = "\(game.numChannels)"
        cell.numViewersLabel.text = "\(game.numViewers)"
        cell.nameLabel.text = game.name
        return cell
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.count
    }

    // MARK: - Modell
    // en större modell skulle nog få en egen modul

    struct Game {
        init(name: String, logoURL: String, numChannels: Int, numViewers: Int) {
            self.name = name
            self.logoURL = logoURL
            self.numChannels = numChannels
            self.numViewers = numViewers
        }
        var name, logoURL: String
        var numChannels, numViewers: Int
    }

    var games: [Game] = []

    var imageCache: [String:UIImage] = [:]
    
    func reloadWithData(data: JSON) {
        games = []
        // man kunde skriva loop nedan funktionellt med t.ex. reduce, men detta är nog lättare att läsa
        for (index: String, subJson: JSON) in data["top"] {
            let gameJSON = subJson["game"]
            if let name = gameJSON["name"].string,
                let logoURL = gameJSON["logo"]["large"].string,
                let numChannels = subJson["channels"].int,
                let numViewers = subJson["viewers"].int {
                    games.append(Game(name: name, logoURL: logoURL,
                        numChannels: numChannels, numViewers: numViewers))
            }
            if getAllLogos {
                for row in 0..<games.count {
                    let url = games[row].logoURL
                    Alamofire.request(.GET, url).response { _, _, data, _ in
                        if data != nil {
                            let image = UIImage(data: data!)
                            self.imageCache[url] = image
                            dispatch_async(dispatch_get_main_queue()) {
                                self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: 0)], withRowAnimation: .None)
                            }
                        }
                    }
                }
            }
        }
        tableView.reloadData()
    }

}

