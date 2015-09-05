//
//  ViewController.swift
//  TwitchTester
//
//  Created by Jakob Cederlund on 2015-09-04.
//  Copyright (c) 2015 dev4phone. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!

    let CellName = "TableViewCell"

    // MARK: - viewDidLoad och HTTP-request
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: CellName, bundle: nil), forCellReuseIdentifier: CellName)
        Alamofire.request(.GET, "https://api.twitch.tv/kraken/games/top",
            parameters: nil, encoding: .URL,
            headers: ["Accept": "application/vnd.twitchtv.v3+json"])
            .responseJSON { request, response, JSON, error in
                dispatch_async(dispatch_get_main_queue()) {
                    self.reloadWithData(JSON)
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
        let row = rows[indexPath.row]
        if let image = imageCache[row.logoURL] {
            cell.logoImageView.image = image
        } else {
            cell.logoImageView.image = nil
            Alamofire.request(.GET, row.logoURL).response { _, _, data, _ in
                if data != nil {
                    let image = UIImage(data: data!)
                    self.imageCache[row.logoURL] = image
                    cell.logoImageView.image = image
                }
            }
        }
        cell.numChannelsLabel.text = "\(row.numChannels)"
        cell.numViewersLabel.text = "\(row.numViewers)"
        cell.nameLabel.text = row.name
        return cell
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    // MARK: - Modell

    // FIXME: här förutsätter jag en massa om json-data, och kraschar om det inte stämmer
    // bättre vore att använda ett riktigt json-bibliotek (som SwiftyJSON)
    struct game {
        init(_ any: AnyObject?) {
            let data = any as! NSDictionary
            let game = data["game"] as! NSDictionary
            self.name = game["name"] as! String
            self.numChannels = data["channels"] as! Int
            self.numViewers = data["viewers"] as! Int
            let logo = game["logo"] as! NSDictionary
            self.logoURL = logo["large"] as! String
        }
        var name, logoURL: String
        var numChannels, numViewers: Int
    }

    var rows: [game] = []

    var imageCache: [String:UIImage] = [:]
    
    func reloadWithData(data: AnyObject?) {
        rows = []
        if let root = data as? NSDictionary {
            if let top = root["top"] as? NSArray {
                rows = map(top) { game($0) }
            }
        }
        tableView.reloadData()
    }

}

