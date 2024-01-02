//
//  ViewControllerReactor.swift
//  Selection
//
//  Created by 김정원 on 12/27/23.
//
import Moya
import ReactorKit
import RxCocoa
import RxSwift
import RxMoya
import Foundation

class ViewControllerReactor: Reactor {
    
    // 사용자 액션을 나타내는 열거형
    enum Action {
        case selectGender(Gender)
        case toggleLayout
        case refreshData
        case moreLoadData(Gender)
        case deleteUser(Gender, IndexPath)

    }
    
    // 상태 변화를 나타내는 열거형
    enum Mutation {
        case setSelectedGender(Gender)
        case setLayout(Int)
        case setMenUsers([RandomMen])
        case setWomenUsers([RandomWomen])
        case setError(Error)
        case resetDataLoadedFlags
        case appendMenUsers([RandomMen])
        case appendWomenUsers([RandomWomen])
        case deleteUser(Gender,IndexPath)
    }
    
    // 뷰의 상태를 나타내는 구조체
    struct State {
        var selectedGender: Gender
        var columnLayout: Int
        var menUsers: [RandomMen]
        var womenUsers: [RandomWomen]
        var isMenDataLoaded : Bool
        var isWomenDataLoaded : Bool
    }
    
    // 성별을 나타내는 열거형
    enum Gender {
        case male
        case female
    }
    
    // 초기 상태 설정
    let initialState: State = State(selectedGender: .male, columnLayout: 1, menUsers: [], womenUsers: [], isMenDataLoaded: false, isWomenDataLoaded: false)
    let provider = MoyaProvider<RandomUserService>()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .moreLoadData(let gender):
            // 추가 데이터 로드
            let service: RandomUserService = (gender == .male) ? .getMenUsers : .getWomenUsers
            return self.provider.rx.request(service)
                .filterSuccessfulStatusCodes()
                .flatMap { response -> Single<Mutation> in
                    do {
                        if gender == .male {
                            let menResponse = try response.map(RandomMenResponse.self)
                            let newUsers = self.currentState.menUsers + menResponse.results
                            return Single.just(Mutation.setMenUsers(newUsers))
                        } else {
                            let womenResponse = try response.map(RandomWomenResponse.self)
                            let newUsers = self.currentState.womenUsers + womenResponse.results
                            return Single.just(Mutation.setWomenUsers(newUsers))
                        }
                    } catch {
                        return Single.just(Mutation.setError(error))
                    }
                }
                .asObservable()
        case let .selectGender(gender):
            // 데이터가 이미 로드된 경우 요청을 보내지 않음
            if (gender == .male && currentState.isMenDataLoaded) ||
                (gender == .female && currentState.isWomenDataLoaded) {
                return Observable.empty()
            }
            // API 서비스 호출
            let service: RandomUserService = (gender == .male) ? .getMenUsers : .getWomenUsers
            return self.provider.rx.request(service)
                .filterSuccessfulStatusCodes()
                .flatMap { response -> Single<Mutation> in
                    do {
                        if gender == .male {
                            let menResponse = try response.map(RandomMenResponse.self)
                            return Single.just(Mutation.setMenUsers(menResponse.results))
                        } else {
                            let womenResponse = try response.map(RandomWomenResponse.self)
                            return Single.just(Mutation.setWomenUsers(womenResponse.results))
                        }
                    } catch {
                        return Single.just(Mutation.setError(error))
                    }
                }
                .asObservable()
            
        case .toggleLayout:
            let newLayout = currentState.columnLayout == 1 ? 2 : 1
            return Observable.just(Mutation.setLayout(newLayout))
        case .refreshData:
            // Reset data loaded flags and fetch new data
            let gender = currentState.selectedGender
            let service: RandomUserService = (gender == .male) ? .getMenUsers : .getWomenUsers
            return self.provider.rx.request(service)
                .filterSuccessfulStatusCodes()
                .flatMap { response -> Single<Mutation> in
                    do {
                        if gender == .male {
                            let menResponse = try response.map(RandomMenResponse.self)
                            return Single.just(Mutation.setMenUsers(menResponse.results))
                        } else {
                            let womenResponse = try response.map(RandomWomenResponse.self)
                            return Single.just(Mutation.setWomenUsers(womenResponse.results))
                        }
                    } catch {
                        return Single.just(Mutation.setError(error))
                    }
                }
                .asObservable()
                .startWith(Mutation.setSelectedGender(gender))
                .concat(Observable.just(Mutation.resetDataLoadedFlags))
        case let .deleteUser(gender, indexPath):
                return Observable.just(Mutation.deleteUser(gender, indexPath))
            
        }
    }
    
    // 뮤테이션으로 상태를 변경하는 함수
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case let .setSelectedGender(gender):
            newState.selectedGender = gender
        case let .setLayout(layout):
            newState.columnLayout = layout
        case let .setMenUsers(users):
            newState.menUsers = users
            newState.isMenDataLoaded = true // 남성 데이터가 로듣
        case let .setWomenUsers(users):
            newState.womenUsers = users
            newState.isWomenDataLoaded = true  // 여성 데이터가 로드되었음을 표시
            
        case .setError(let error):
            print("Error: \(error)")
            
        case .resetDataLoadedFlags:
            newState.isMenDataLoaded = false
            newState.isWomenDataLoaded = false
        case let .appendMenUsers(newUsers):
            newState.menUsers.append(contentsOf: newUsers)
        case let .appendWomenUsers(newUsers):
            newState.womenUsers.append(contentsOf: newUsers)
        case let .deleteUser(gender, indexPath):
              if gender == .male {
                  newState.menUsers.remove(at: indexPath.row)
              } else {
                  newState.womenUsers.remove(at: indexPath.row)
              }
        }
        return newState
    }
}
