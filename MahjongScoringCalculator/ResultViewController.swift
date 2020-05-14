import UIKit

class ResultViewController: UIViewController {

    @IBOutlet weak var result: UILabel!
    
    @IBOutlet weak var resultList: UILabel!
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    var tileDataset: [String] = []
    
    var resultText: String = ""
    
    var resultListText: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let resolvedTile = self.resolveTile(data: tileDataset)
        self.isWin(data: resolvedTile)
//        result?.text = sortedtileData.joined(separator: ", ")

    }
    
    func isWin(data: [String]) -> Bool {
        
        var pair: Int = 0 // 2 same tile
        var chow: Int = 0 // 3 suited tile in sequence  eg: 1dots, 2dots, 3dots
        var pong: Int = 0 // 3 same tile
        var pongTile: [Int] = [] // Type of tile
        var kong: Int = 0 // 4 same tile
        var word: Int = 0 // honors

        if (data.count < 14) {
            result?.text = "Not enough tiles!"
            return false
        }
        
        
        var analyzedData: [String: Int] = [:]

        // Count the number of same tile
        for item in data {
            analyzedData[item] = (analyzedData[item] ?? 0) + 1
        }
        
        
//        print("////// \(analyzedData)")
                        
        let keys = Array(analyzedData.keys)
        for i in keys {
            if (analyzedData[i] == 4) { // pull out the kongs
                kong += 1
                if (i == "31" || i == "32" || i == "33" || i == "34" || i == "35" || i == "36" || i == "37") {
                    word += 1
                }
                analyzedData[i] = nil
            } else if (analyzedData[i] == 3) { // pull out the pongs
                pong += 1
                if (i == "31" || i == "32" || i == "33" || i == "34" || i == "35" || i == "36" || i == "37") {
                    word += 1
                }
                pongTile.append(Int(i)!)
                analyzedData[i] = nil
            } else if (analyzedData[i] == 2) { // pull out the pairs
                pair += 1
                if (i == "31" || i == "32" || i == "33" || i == "34" || i == "35" || i == "36" || i == "37") {
                    word += 1
                }
                analyzedData[i] = nil
            }
        }
        
        var sortedData = analyzedData.sorted(by: <)
        
//        print("//////??? \(sortedData)")
        
        // Cal. chow
        if (!sortedData.isEmpty){
            if (sortedData.count >= 3) {
                for i in 0...(sortedData.count-3) {
                    
                    // Counting without honors
                    if ( Int(sortedData[i].key)! < 31) {
                        // Suited tile in sequence
                        if ( ( (Int(sortedData[i].key)! + 1) == Int(sortedData[i + 1].key) ) &&
                            ( (Int(sortedData[i].key)! + 2) == Int(sortedData[i + 2].key) ) ) {
                            
                            if (sortedData[i].value > 0 && sortedData[i + 1].value > 0 && sortedData[i + 2].value > 0) {
                                chow += 1
                                sortedData[i].value -= 1
                                sortedData[i + 1].value -= 1
                                sortedData[i + 2].value -= 1
                            }
                            
                        }
                    }
                }
            }
        }
        
//        print("////// \(pair) /// \(pong) /// \(kong) /// \(chow)")
//        print("//////??? \(pongTile)")
        
        if ((chow + pong + kong) == 4 && pair == 1) {
            self.scoreCalculate(chow: chow, pong: pong, kong: kong, pair: pair, pongTile: pongTile, word: word)
            return true
        } else {
            resultText = "You Lose: 0番!"
            resultListText = ""
            result.text = resultText
            resultList.text = resultListText
            return false
        }
        
    }
    
    func scoreCalculate(chow: Int, pong: Int, kong: Int, pair: Int, pongTile: [Int], word: Int) -> () {
        var fann: Int = 0
        if (kong > 0) {
            resultListText += "\n槓 x\(kong) = \(kong)番"
            fann += kong
        }
        if (pong > 0) {
            if (pong == 2) {
                if (pongTile[0] < 31 && pongTile[1] < 31) {
                    if ( (pongTile[0] + 10) == pongTile[1] || (pongTile[0] - 10) == pongTile[1]) {
                        resultListText += "\n雙同刻 x1 = 3番"
                        fann += 3
                    }
                }
            }
            for i in 0 ..< pongTile.count {
                var count = 0
                if (pongTile[i] == 35 || pongTile[i] == 36 || pongTile[i] == 37) {
                    resultListText += "\n三元牌 x1 = 1番"
                    count += 1
                }
                if (pong == 3) {
                    if (pongTile[i] == 35 || pongTile[i] == 36 || pongTile[i] == 37) {
                        count += 1
                    }
                }
                if (i == pongTile.count - 1) {
                    if (count == 3) {
                        resultListText += "\n大三元 x1 = 10番"
                        fann += 10
                    } else {
                        fann += count
                    }
                }
            }
            if (pong == 4) {
                resultListText += "\n對對胡 x1 = 5番"
                fann += 5
            }
        }
        if (word == 0) {
            if (chow == 4) {
                resultListText += "\n平糊 x1 = 3番"
                fann += 3
            } else {
                resultListText += "\n無字 x1 = 1番"
                fann += 1
            }
        }
        resultListText += "\n無花 x1 = 1番"
        fann += 1
        
        resultText = "You Win: \(fann)番!"
        
        result.text = resultText
        resultList.text = resultListText
    }
    

    func resolveTile(data: [String]) -> [String] {
        var resolvedData: [String] = []
        for i in 0 ..< data.count {
            switch data[i] {
            case "characters-1":
                resolvedData.append("1")
                break
            case "characters-2":
                resolvedData.append("2")
                break
            case "characters-3":
                resolvedData.append("3")
                break
            case "characters-4":
                resolvedData.append("4")
                break
            case "characters-5":
                resolvedData.append("5")
                break
            case "characters-6":
                resolvedData.append("6")
                break
            case "characters-7":
                resolvedData.append("7")
                break
            case "characters-8":
                resolvedData.append("8")
                break
            case "characters-9":
                resolvedData.append("9")
                break
            case "dots-1":
                resolvedData.append("11")
                break
            case "dots-2":
                resolvedData.append("12")
                break
            case "dots-3":
                resolvedData.append("13")
                break
            case "dots-4":
                resolvedData.append("14")
                break
            case "dots-5":
                resolvedData.append("15")
                break
            case "dots-6":
                resolvedData.append("16")
                break
            case "dots-7":
                resolvedData.append("17")
                break
            case "dots-8":
                resolvedData.append("18")
                break
            case "dots-9":
                resolvedData.append("19")
                break
            case "bamboo-1":
                resolvedData.append("21")
                break
            case "bamboo-2":
                resolvedData.append("22")
                break
            case "bamboo-3":
                resolvedData.append("23")
                break
            case "bamboo-4":
                resolvedData.append("24")
                break
            case "bamboo-5":
                resolvedData.append("25")
                break
            case "bamboo-6":
                resolvedData.append("26")
                break
            case "bamboo-7":
                resolvedData.append("27")
                break
            case "bamboo-8":
                resolvedData.append("28")
                break
            case "bamboo-9":
                resolvedData.append("29")
                break
            case "honors-east":
                resolvedData.append("31")
                break
            case "honors-south":
                resolvedData.append("32")
                break
            case "honors-west":
                resolvedData.append("33")
                break
            case "honors-north":
                resolvedData.append("34")
                break
            case "honors-red":
                resolvedData.append("35")
                break
            case "honors-green":
                resolvedData.append("36")
                break
            case "honors-white":
                resolvedData.append("37")
                break
            default:
                break
            }
        }
        return resolvedData
    }
}
