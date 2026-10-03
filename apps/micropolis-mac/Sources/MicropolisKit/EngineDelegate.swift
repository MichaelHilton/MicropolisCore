import Foundation

public protocol EngineDelegate: AnyObject {
    func engineDidLoadCity(filename: String)
    func engineDidGenerateMap(seed: Int)
    func engineDidTool(name: String, x: Int, y: Int)
    func engineMakeSound(channel: String, sound: String, x: Int, y: Int)
    func engineSendMessage(index: Int, x: Int, y: Int, picture: Bool, important: Bool)
    func engineAutoGoto(x: Int, y: Int, message: String)
    func engineShowBudgetAndWait()
    func engineShowZoneStatus(category: Int, density: Int, landValue: Int, crime: Int, pollution: Int, growth: Int, x: Int, y: Int)
    func engineUpdateDate(year: Int, month: Int)
    func engineUpdateFunds(funds: Int)
    func engineUpdateDemand(residential: Float, commercial: Float, industrial: Float)
    func engineUpdateCityName(name: String)
    func engineUpdateEvaluation()
    func engineUpdateHistory()
    func engineUpdateBudget()
    func engineUpdatePaused(paused: Bool)
    func engineUpdateSpeed(speed: Int)
    func engineUpdateTaxRate(tax: Int)
    func engineStartEarthquake(strength: Int)
    func engineDidWinGame()
    func engineDidLoseGame()
}

extension EngineDelegate {
    public func engineDidLoadCity(filename: String) {}
    public func engineDidGenerateMap(seed: Int) {}
    public func engineDidTool(name: String, x: Int, y: Int) {}
    public func engineMakeSound(channel: String, sound: String, x: Int, y: Int) {}
    public func engineSendMessage(index: Int, x: Int, y: Int, picture: Bool, important: Bool) {}
    public func engineAutoGoto(x: Int, y: Int, message: String) {}
    public func engineShowBudgetAndWait() {}
    public func engineShowZoneStatus(category: Int, density: Int, landValue: Int, crime: Int, pollution: Int, growth: Int, x: Int, y: Int) {}
    public func engineUpdateDate(year: Int, month: Int) {}
    public func engineUpdateFunds(funds: Int) {}
    public func engineUpdateDemand(residential: Float, commercial: Float, industrial: Float) {}
    public func engineUpdateCityName(name: String) {}
    public func engineUpdateEvaluation() {}
    public func engineUpdateHistory() {}
    public func engineUpdateBudget() {}
    public func engineUpdatePaused(paused: Bool) {}
    public func engineUpdateSpeed(speed: Int) {}
    public func engineUpdateTaxRate(tax: Int) {}
    public func engineStartEarthquake(strength: Int) {}
    public func engineDidWinGame() {}
    public func engineDidLoseGame() {}
}
