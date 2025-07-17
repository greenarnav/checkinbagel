//
//  CelebritySocialLinks.swift
//  moodgpt
//
//  Created by Test on 12/21/24.
//

import Foundation

struct CelebritySocialLinks {
    
    // MARK: - Celebrity Social Media Database
    static let socialMediaLinks: [String: CelebrityLinks] = [
        
        // MUSIC CELEBRITIES
        "Taylor Swift": CelebrityLinks(
            instagram: "taylorswift",
            twitter: "taylorswift13"
        ),
        "Ariana Grande": CelebrityLinks(
            instagram: "arianagrande",
            twitter: "arianagrande"
        ),
        "Drake": CelebrityLinks(
            instagram: "champagnepapi",
            twitter: "drake"
        ),
        "Billie Eilish": CelebrityLinks(
            instagram: "billieeilish",
            twitter: "billieeilish"
        ),
        "Ed Sheeran": CelebrityLinks(
            instagram: "teddysphotos",
            twitter: "edsheeran"
        ),
        "Rihanna": CelebrityLinks(
            instagram: "badgalriri",
            twitter: "rihanna"
        ),
        "Justin Bieber": CelebrityLinks(
            instagram: "justinbieber",
            twitter: "justinbieber"
        ),
        "Dua Lipa": CelebrityLinks(
            instagram: "dualipa",
            twitter: "dualipa"
        ),
        "Post Malone": CelebrityLinks(
            instagram: "postmalone",
            twitter: "postmalone"
        ),
        "Olivia Rodrigo": CelebrityLinks(
            instagram: "oliviarodrigo",
            twitter: "oliviarodrigo"
        ),
        
        // ACTORS & ACTRESSES
        "Dwayne Johnson": CelebrityLinks(
            instagram: "therock",
            twitter: "therock"
        ),
        "Ryan Reynolds": CelebrityLinks(
            instagram: "vancityreynolds",
            twitter: "vancityreynolds"
        ),
        "Jennifer Lawrence": CelebrityLinks(
            instagram: "jenniferlawrence",
            twitter: "jenniferlawrence"
        ),
        "Chris Evans": CelebrityLinks(
            instagram: "chrisevans",
            twitter: "chrisevans"
        ),
        "Emma Stone": CelebrityLinks(
            instagram: "emmastone",
            twitter: "emmastone"
        ),
        "Leonardo DiCaprio": CelebrityLinks(
            instagram: "leonardodicaprio",
            twitter: "leodicaprio"
        ),
        "Margot Robbie": CelebrityLinks(
            instagram: "margotrobbie",
            twitter: "margotrobbie"
        ),
        "Tom Holland": CelebrityLinks(
            instagram: "tomholland2013",
            twitter: "tomholland2013"
        ),
        "Zendaya": CelebrityLinks(
            instagram: "zendaya",
            twitter: "zendaya"
        ),
        "Robert Downey Jr": CelebrityLinks(
            instagram: "robertdowneyjr",
            twitter: "robertdowneyjr"
        ),
        
        // SOCIAL MEDIA INFLUENCERS
        "Kylie Jenner": CelebrityLinks(
            instagram: "kyliejenner",
            twitter: "kyliejenner"
        ),
        "Kim Kardashian": CelebrityLinks(
            instagram: "kimkardashian",
            twitter: "kimkardashian"
        ),
        "Khloé Kardashian": CelebrityLinks(
            instagram: "khloekardashian",
            twitter: "khloekardashian"
        ),
        "James Charles": CelebrityLinks(
            instagram: "jamescharles",
            twitter: "jamescharles"
        ),
        "Emma Chamberlain": CelebrityLinks(
            instagram: "emmachamberlain",
            twitter: "emmachamberlain"
        ),
        
        // SPORTS CELEBRITIES
        "Cristiano Ronaldo": CelebrityLinks(
            instagram: "cristiano",
            twitter: "cristiano"
        ),
        "Lionel Messi": CelebrityLinks(
            instagram: "leomessi",
            twitter: "wearemessi"
        ),
        "LeBron James": CelebrityLinks(
            instagram: "kingjames",
            twitter: "kingjames"
        ),
        "Serena Williams": CelebrityLinks(
            instagram: "serenawilliams",
            twitter: "serenawilliams"
        ),
        "Stephen Curry": CelebrityLinks(
            instagram: "stephencurry30",
            twitter: "stephencurry30"
        ),
        "Usain Bolt": CelebrityLinks(
            instagram: "usainbolt",
            twitter: "usainbolt"
        ),
        
        // BUSINESS & TECH
        "Elon Musk": CelebrityLinks(
            instagram: "elonmusk",
            twitter: "elonmusk"
        ),
        "Bill Gates": CelebrityLinks(
            instagram: "thisisbillgates",
            twitter: "billgates"
        ),
        "Mark Zuckerberg": CelebrityLinks(
            instagram: "zuck",
            twitter: "finkd"
        ),
        "Jeff Bezos": CelebrityLinks(
            instagram: "jeffbezos",
            twitter: "jeffbezos"
        ),
        
        // POLITICIANS
        "Barack Obama": CelebrityLinks(
            instagram: "barackobama",
            twitter: "barackobama"
        ),
        "Michelle Obama": CelebrityLinks(
            instagram: "michelleobama",
            twitter: "michelleobama"
        ),
        
        // COMEDIANS
        "Kevin Hart": CelebrityLinks(
            instagram: "kevinhart4real",
            twitter: "kevinhart4real"
        ),
        "Amy Schumer": CelebrityLinks(
            instagram: "amyschumer",
            twitter: "amyschumer"
        ),
        "Trevor Noah": CelebrityLinks(
            instagram: "trevornoah",
            twitter: "trevornoah"
        ),
        
        // TV PERSONALITIES
        "Oprah Winfrey": CelebrityLinks(
            instagram: "oprah",
            twitter: "oprah"
        ),
        "Ellen DeGeneres": CelebrityLinks(
            instagram: "theellenshow",
            twitter: "theellenshow"
        ),
        "Jimmy Fallon": CelebrityLinks(
            instagram: "jimmyfallon",
            twitter: "jimmyfallon"
        )
    ]
    
    // MARK: - Helper Methods
    
    static func getInstagramHandle(for celebrityName: String) -> String? {
        return socialMediaLinks[celebrityName]?.instagram
    }
    
    static func getTwitterHandle(for celebrityName: String) -> String? {
        return socialMediaLinks[celebrityName]?.twitter
    }
    
    static func getSocialLinks(for celebrityName: String) -> CelebrityLinks? {
        return socialMediaLinks[celebrityName]
    }
    
    static func getInstagramURL(for celebrityName: String) -> String? {
        guard let handle = getInstagramHandle(for: celebrityName) else { return nil }
        return "https://instagram.com/\(handle)"
    }
    
    static func getTwitterURL(for celebrityName: String) -> String? {
        guard let handle = getTwitterHandle(for: celebrityName) else { return nil }
        return "https://twitter.com/\(handle)"
    }
    
    static func getAllCelebrityNames() -> [String] {
        return Array(socialMediaLinks.keys).sorted()
    }
}

// MARK: - Celebrity Links Model
struct CelebrityLinks {
    let instagram: String?
    let twitter: String?
    
    init(instagram: String? = nil, twitter: String? = nil) {
        self.instagram = instagram
        self.twitter = twitter
    }
} 