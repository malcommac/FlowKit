//
//  ExampleTableController.swift
//  Example
//
//  Created by dan on 28/03/2019.
//  Copyright © 2019 FlowKit2. All rights reserved.
//

import UIKit

public class TeamPlayersController: UIViewController {

	static func create() -> TeamPlayersController {
		let storyboard = UIStoryboard(name: "TeamPlayersController", bundle: Bundle.main)
		return storyboard.instantiateViewController(withIdentifier: "TeamPlayersController") as! TeamPlayersController
	}

}
