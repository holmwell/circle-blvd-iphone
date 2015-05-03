//
//  SessionViewProtocol
//  Circle Blvd
//
//  Created by Phil Manijak on 4/4/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import Foundation

@objc protocol SessionViewProtocol {
    
    var session: NSURLSession? { get set }
    var baseUrl: String? { get set }
    var profile: NSDictionary? { get set }
}
