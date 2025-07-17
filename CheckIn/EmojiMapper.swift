//
//  EmojiMapper.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import Foundation

// MARK: - Emoji Mapper
struct EmojiMapper {
    
    // MARK: - Available Emojis (97 total)
    static let availableEmojis: [String] = [
        // Happy emotions (26 emojis)
        "😊", "😄", "😃", "😁", "😂", "🤣", "😍", "🥰", "😘", "😗", 
        "😙", "😚", "😉", "🤗", "🥳", "🤩", "😌", "😇", "🙃", "😋", 
        "😛", "😜", "🤪", "😝", "🤤", "😏",
        
        // Sad emotions (19 emojis)
        "😢", "😭", "😿", "😥", "😰", "😨", "😧", "😦", "😔", "😞", 
        "😟", "😕", "🙁", "☹️", "😣", "😖", "😫", "😩", "🥺",
        
        // Angry emotions (5 emojis)
        "😠", "😡", "🤬", "😤", "😮‍💨",
        
        // Surprised emotions (6 emojis)
        "😮", "😯", "😲", "😳", "🤯", "😱",
        
        // Neutral/Other emotions (27 emojis)
        "😐", "😑", "😶", "🤐", "🤔", "🤫", "🤭", "😬", "🙄", "😒", 
        "🧐", "🤨", "😴", "😪", "🥱", "😵", "🥴", "🤢", 
        "🤮", "🤧", "🤒", "🤕", "🥵", "🥶", "🥸", "🫨", "🫠",
        
        // Professional/Other emojis (13 emojis)
        "💼", "📈", "📊", "📰", "🤝", "💰", "🌏", "🏥", "🏢", 
        "🌍", "💪", "🏃‍♂️", "🔬", "📱", "🤓", "📞", "💡", 
        "🎯", "🚀", "💻", "📚",
        
        // Emotions (from user's approved list)
        "angry", "anguished", "anxios-with-sweat", "astonished", "bandage-face", "big-frown", "blush", "cold-face", "concerned", "cry",
        "cursing", "diagonal-mouth", "distraught", "dizzy-face", "drool", "exhale", "expressionless", "flushed", "frown", "gasp",
        "grimacing", "grin-sweat", "grin", "grinning", "hand-over-mouth", "happy-cry", "head-nod", "head-shake", "heart-eyes", "heart-face",
        "holding-back-tears", "hot-face", "hug-face", "joy", "kissing-closed-eyes", "kissing-heart", "kissing-smile", "kissing",
        "laughing", "loudly-crying", "melting", "mind-blown", "monocle", "mouth-none", "mouth-open", "neutral-face", "partying-face",
        "peeking", "pensive", "pleading", "rage", "raised-eyebrow", "relieved", "rofl", "rolling-eyes", "sad", "scared",
        "screaming", "scrunched-eyes", "scrunched-mouth", "shaking-face", "shushing-face", "sick", "similing-eyes-with-hand-over-mouth",
        "sleep", "sleepy", "slightly-frowning", "slightly-happy", "smile-with-big-eyes", "smile", "smirk", "sneeze", "squinting-tongue",
        "star-struck", "stick-out-tounge", "surprised", "sweat", "thermometer-face", "thinking-face", "tired", "triumph", "unamused",
        "upside-down-face", "vomit", "warm-smile", "weary", "wink", "winky-tongue", "woozy", "worried", "x-eyes", "yawn", "yum", "zany-face", "zipper-face"
    ]
    
    // MARK: - Validation
    static func isValidEmoji(_ emoji: String) -> Bool {
        return availableEmojis.contains(emoji)
    }
    
    // MARK: - GIF File Validation
    static func hasGifFile(for emoji: String) -> Bool {
        let gifFileName = getGifName(for: emoji)
        return Bundle.main.url(forResource: gifFileName, withExtension: "gif") != nil
    }
    


    static func getGifName(for emoji: String) -> String {
        switch emoji {
        // Happy emotions
        case "😊", "happy": return "Smile"
        case "smile": return "Smile"
        case "😄", "grinning": return "grinning"
        case "😃", "grin": return "grin"
        case "😁", "laughing": return "laughing"
        case "😂", "joy": return "joy"
        case "🤣", "rofl": return "rofl"
        case "😍", "heart-eyes": return "heart-eyes"
        case "🥰", "heart-face": return "heart-face"
        case "😘", "kissing-heart": return "kissing-heart"
        case "😗", "kissing": return "kissing"
        case "😙", "kissing-smile": return "kissing-smile"
        case "😚", "kissing-closed-eyes": return "kissing-closed-eyes"
        case "😉", "wink": return "wink"
        case "🤗", "hug-face": return "hug-face"
        case "🥳", "partying-face": return "partying-face"
        case "🤩", "star-struck": return "star-struck"
        case "😌", "relieved": return "relieved"
        case "😇", "slightly-happy": return "slightly-happy"
        case "🙃", "upside-down": return "upside-down-face"
        case "😋", "yum": return "yum"
        case "😛", "stick-out-tongue": return "stick-out-tounge"
        case "😜", "winky-tongue": return "winky-toungue"
        case "🤪", "zany": return "zany-face"
        case "😝", "squinting-tongue": return "squinting-tounge"
        case "🤤", "drool": return "drool"
        case "😏", "smirk": return "smirk"
        case "😊😇", "warm-smile": return "warm-smile"
        case "😊😌", "blush": return "blush"
        case "🫠", "melting": return "melting"
        
        // Sad emotions
        case "😢", "sad", "cry": return "sad"
        case "😭", "loudly-crying": return "loudly-crying"
        case "😿", "crying": return "cry"
        case "😥", "sweat": return "sweat"
        case "😰", "anxious": return "anxios-with-sweat"
        case "😨", "scared": return "scared"
        case "😧", "anguished": return "anguished"
        case "😦", "frown": return "frown"
        case "😔", "pensive": return "pensive"
        case "😞", "big-frown": return "big-frown"
        case "😟", "worried": return "worried"
        case "😕", "slightly-frowning": return "Slightly-frowning"
        case "🙁", "concerned": return "concerned"
        case "☹️", "diagonal-mouth": return "Diagonal-mouth"
        case "😣", "weary": return "weary"
        case "😖", "scrunched-eyes": return "scrunched-eyes"
        case "😫", "distraught": return "distraught"
        case "😩", "tired": return "tired"
        case "🥺", "pleading": return "pleading"
        case "😢😭", "holding-back-tears": return "holding-back-tears"
        case "😭😊", "happy-cry": return "happy-cry"
        
        // Angry emotions
        case "😠", "angry": return "angry"
        case "😡", "rage": return "rage"
        case "🤬", "cursing": return "cursing"
        case "😤", "triumph": return "triumph"
        case "😮‍💨", "exhale": return "exhale"
        
        // Surprised emotions
        case "😮", "surprised", "mouth-open": return "surprised"
        case "😯", "gasp": return "gasp"
        case "😲", "astonished": return "astonished"
        case "😳", "flushed": return "flushed"
        case "🤯", "mind-blown": return "mind--blown"
        case "😱", "screaming": return "screaming"
        
        // Neutral/Other emotions
        case "😐", "neutral": return "neutral-face"
        case "neutral-face": return "neutral-face"
        case "😑", "expressionless": return "expressionless"
        case "😶", "mouth-none": return "mouth-none"
        case "🤐", "zipper": return "zipper-face"
        case "🤔", "thinking": return "thinking-face"
        case "thinking-face": return "thinking-face"
        case "🤫", "shushing": return "shushing-face"
        case "🤭", "hand-over-mouth": return "hand-over-mouth"
        case "😬", "grimacing": return "grimacing"
        case "🙄", "rolling-eyes": return "rolling-eyes"
        case "😒", "unamused": return "unamused"
        case "🧐", "monocle": return "monocle"
        case "🤨", "raised-eyebrow": return "raised-eyebrow"
        case "😴", "sleepy": return "sleepy"
        case "😪", "sleep": return "sleep"
        case "🥱", "yawn": return "yawn"
        case "😵", "dizzy": return "dizzy-face"
        case "😵‍💫", "x-eyes": return "x-eyes"
        case "🥴", "woozy": return "woozy"
        case "🤢", "sick": return "sick"
        case "🤮", "vomit": return "vomit"
        case "🤧", "sneeze": return "sneeze"
        case "🤒", "thermometer": return "thermometer-face"
        case "🤕", "bandage": return "bandage-face"
        case "🥵", "hot": return "hot-face"
        case "🥶", "cold": return "cold-fcae"
        case "🥸", "peeking": return "peeking"
        case "🫨", "shaking": return "shaking-face"
        
        // Default fallback
        default: return "Smile"
        }
    }
    
    // MARK: - Unicode Emoji Mapping
    /// Convert emotion name to actual Unicode emoji for fallback display
    static func getUnicodeEmoji(for emotionName: String) -> String {
        switch emotionName {
        // Happy emotions
        case "smile": return "😊"
        case "grinning": return "😄"
        case "grin": return "😃"
        case "laughing": return "😁"
        case "joy": return "😂"
        case "rofl": return "🤣"
        case "heart-eyes": return "😍"
        case "heart-face": return "🥰"
        case "kissing-heart": return "😘"
        case "kissing": return "😗"
        case "kissing-smile": return "😙"
        case "kissing-closed-eyes": return "😚"
        case "wink": return "😉"
        case "hug-face": return "🤗"
        case "partying-face": return "🥳"
        case "star-struck": return "🤩"
        case "relieved": return "😌"
        case "slightly-happy": return "😇"
        case "upside-down-face": return "🙃"
        case "yum": return "😋"
        case "stick-out-tounge": return "😛"
        case "winky-toungue": return "😜"
        case "zany-face": return "🤪"
        case "squinting-tounge": return "😝"
        case "drool": return "🤤"
        case "smirk": return "😏"
        case "warm-smile": return "😊"
        case "blush": return "😊"
        case "melting": return "🫠"
        
        // Sad emotions
        case "sad": return "😢"
        case "cry": return "😢"
        case "loudly-crying": return "😭"
        case "sweat": return "😥"
        case "anxios-with-sweat": return "😰"
        case "scared": return "😨"
        case "anguished": return "😧"
        case "frown": return "😦"
        case "pensive": return "😔"
        case "big-frown": return "😞"
        case "worried": return "😟"
        case "Slightly-frowning": return "😕"
        case "concerned": return "🙁"
        case "Diagonal-mouth": return "☹️"
        case "weary": return "😣"
        case "scrunched-eyes": return "😖"
        case "distraught": return "😫"
        case "tired": return "😩"
        case "pleading": return "🥺"
        case "holding-back-tears": return "😢"
        case "happy-cry": return "😭"
        
        // Angry emotions
        case "angry": return "😠"
        case "rage": return "😡"
        case "cursing": return "🤬"
        case "triumph": return "😤"
        case "exhale": return "😮‍💨"
        
        // Surprised emotions
        case "surprised": return "😮"
        case "mouth-open": return "😮"
        case "gasp": return "😯"
        case "astonished": return "😲"
        case "flushed": return "😳"
        case "mind--blown": return "🤯"
        case "screaming": return "😱"
        
        // Neutral/Other emotions
        case "neutral-face": return "😐"
        case "expressionless": return "😑"
        case "mouth-none": return "😶"
        case "zipper-face": return "🤐"
        case "thinking-face": return "🤔"  // ← This is the key one for your issue!
        case "shushing-face": return "🤫"
        case "hand-over-mouth": return "🤭"
        case "grimacing": return "😬"
        case "rolling-eyes": return "🙄"
        case "unamused": return "😒"
        case "monocle": return "🧐"
        case "raised-eyebrow": return "🤨"
        case "sleepy": return "😴"
        case "sleep": return "😪"
        case "yawn": return "🥱"
        case "dizzy-face": return "😵"
        case "x-eyes": return "😵‍💫"
        case "woozy": return "🥴"
        case "sick": return "🤢"
        case "vomit": return "🤮"
        case "sneeze": return "🤧"
        case "thermometer-face": return "🤒"
        case "bandage-face": return "🤕"
        case "hot-face": return "🥵"
        case "cold-fcae": return "🥶"
        case "peeking": return "🥸"
        case "shaking-face": return "🫨"
        
        // Default fallback
        default: return "😊"
        }
    }

    // MARK: - ID Mapping for API Compatibility
    
    /// Convert emoji name to ID for API usage
    static func idForEmoji(_ emojiName: String) -> Int {
        // Map common emoji names to their IDs
        switch emojiName {
        case "angry": return 1
        case "anguished": return 2
        case "anxios-with-sweat": return 3
        case "astonished": return 4
        case "bandage-face": return 5
        case "big-frown": return 6
        case "blush": return 7
        case "cold-face": return 8
        case "concerned": return 9
        case "cry": return 10
        case "cursing": return 11
        case "diagonal-mouth": return 12
        case "distraught": return 13
        case "dizzy-face": return 14
        case "drool": return 15
        case "exhale": return 16
        case "expressionless": return 17
        case "flushed": return 18
        case "frown": return 19
        case "gasp": return 20
        case "grimacing": return 21
        case "grin-sweat": return 22
        case "grin": return 23
        case "grinning": return 24
        case "hand-over-mouth": return 25
        case "happy-cry": return 26
        case "smile": return 27
        case "heart-eyes": return 29
        case "heart-face": return 30
        case "holding-back-tears": return 31
        case "hot-face": return 32
        case "hug-face": return 33
        case "joy": return 34
        case "kissing-closed-eyes": return 35
        case "kissing-heart": return 36
        case "kissing-smile": return 37
        case "kissing": return 38
        case "laughing": return 39
        case "loudly-crying": return 40
        case "melting": return 41
        case "mind-blown": return 42
        case "monocle": return 43
        case "mouth-none": return 44
        case "mouth-open": return 45
        case "neutral-face": return 46
        case "partying-face": return 47
        case "peeking": return 48
        case "pensive": return 49
        case "pleading": return 50
        case "rage": return 51
        case "raised-eyebrow": return 52
        case "relieved": return 53
        case "rofl": return 54
        case "rolling-eyes": return 55
        case "sad": return 56
        case "scared": return 57
        case "screaming": return 58
        case "scrunched-eyes": return 59
        case "scrunched-mouth": return 60
        case "shaking-face": return 61
        case "shushing-face": return 62
        case "sick": return 63
        case "similing-eyes-with-hand-over-mouth": return 64
        case "sleep": return 65
        case "sleepy": return 66
        case "slightly-frowning": return 67
        case "slightly-happy": return 68
        case "smile-with-big-eyes": return 69
        case "smirk": return 71
        case "sneeze": return 72
        case "squinting-tounge": return 73
        case "star-struck": return 74
        case "stick-out-tounge": return 75
        case "surprised": return 76
        case "sweat": return 77
        case "thermometer-face": return 78
        case "thinking-face": return 79
        case "tired": return 80
        case "triumph": return 81
        case "unamused": return 82
        case "upside-down-face": return 83
        case "vomit": return 84
        case "warm-smile": return 85
        case "weary": return 86
        case "wink": return 87
        case "winky-toungue": return 88
        case "woozy": return 89
        case "worried": return 90
        case "x-eyes": return 91
        case "yawn": return 92
        case "yum": return 93
        case "zany-face": return 94
        case "zipper-face": return 95
        default: return 46 // Default to neutral-face
        }
    }
    
    /// Convert emoji ID back to emoji name for display
    static func getEmojiForID(_ emojiID: Int) -> String? {
        // Reverse mapping from ID to emoji name
        switch emojiID {
        case 1: return "angry"
        case 2: return "anguished"
        case 3: return "anxios-with-sweat"
        case 4: return "astonished"
        case 5: return "bandage-face"
        case 6: return "big-frown"
        case 7: return "blush"
        case 8: return "cold-face"
        case 9: return "concerned"
        case 10: return "cry"
        case 11: return "cursing"
        case 12: return "diagonal-mouth"
        case 13: return "distraught"
        case 14: return "dizzy-face"
        case 15: return "drool"
        case 16: return "exhale"
        case 17: return "expressionless"
        case 18: return "flushed"
        case 19: return "frown"
        case 20: return "gasp"
        case 21: return "grimacing"
        case 22: return "grin-sweat"
        case 23: return "grin"
        case 24: return "grinning"
        case 25: return "hand-over-mouth"
        case 26: return "happy-cry"
        case 27: return "smile"
        case 29: return "heart-eyes"
        case 30: return "heart-face"
        case 31: return "holding-back-tears"
        case 32: return "hot-face"
        case 33: return "hug-face"
        case 34: return "joy"
        case 35: return "kissing-closed-eyes"
        case 36: return "kissing-heart"
        case 37: return "kissing-smile"
        case 38: return "kissing"
        case 39: return "laughing"
        case 40: return "loudly-crying"
        case 41: return "melting"
        case 42: return "mind-blown"
        case 43: return "monocle"
        case 44: return "mouth-none"
        case 45: return "mouth-open"
        case 46: return "neutral-face"
        case 47: return "partying-face"
        case 48: return "peeking"
        case 49: return "pensive"
        case 50: return "pleading"
        case 51: return "rage"
        case 52: return "raised-eyebrow"
        case 53: return "relieved"
        case 54: return "rofl"
        case 55: return "rolling-eyes"
        case 56: return "sad"
        case 57: return "scared"
        case 58: return "screaming"
        case 59: return "scrunched-eyes"
        case 60: return "scrunched-mouth"
        case 61: return "shaking-face"
        case 62: return "shushing-face"
        case 63: return "sick"
        case 64: return "similing-eyes-with-hand-over-mouth"
        case 65: return "sleep"
        case 66: return "sleepy"
        case 67: return "slightly-frowning"
        case 68: return "slightly-happy"
        case 69: return "smile-with-big-eyes"
        case 71: return "smirk"
        case 72: return "sneeze"
        case 73: return "squinting-tounge"
        case 74: return "star-struck"
        case 75: return "stick-out-tounge"
        case 76: return "surprised"
        case 77: return "sweat"
        case 78: return "thermometer-face"
        case 79: return "thinking-face"
        case 80: return "tired"
        case 81: return "triumph"
        case 82: return "unamused"
        case 83: return "upside-down-face"
        case 84: return "vomit"
        case 85: return "warm-smile"
        case 86: return "weary"
        case 87: return "wink"
        case 88: return "winky-toungue"
        case 89: return "woozy"
        case 90: return "worried"
        case 91: return "x-eyes"
        case 92: return "yawn"
        case 93: return "yum"
        case 94: return "zany-face"
        case 95: return "zipper-face"
        default: return "neutral-face" // Default fallback
        }
    }
    
    // MARK: - Get Fixed Timeline Emojis (consistent, no randomness)
    static func getTimelineEmoji(for period: TimelinePeriod) -> String {
        switch period {
        case .morningRest:
            return "😴" // sleepy
        case .afternoonEnergizing:
            return "😄" // energetic/grinning
        case .eveningHappy:
            return "😊" // happy
        case .nextMorningGood:
            return "🙃" // good
        case .nextAfternoonFocused:
            return "🤔" // focused/thinking
        case .nextEveningContent:
            return "😌" // content/relieved
        }
    }
    
    enum TimelinePeriod {
        case morningRest, afternoonEnergizing, eveningHappy
        case nextMorningGood, nextAfternoonFocused, nextEveningContent
    }
} 
