# 📔 일기장
> 프로젝트 기간: 2022-06-13 ~ 2022-07-01
> 
> 팀원: [dudu](https://github.com/firstDo), [papri](https://github.com/papriOS) 
> 
> 리뷰어: [린생](https://github.com/jungseungyeo)

## 🔎 프로젝트 소개

> 날씨도 저장되는 나만의 일기장

## 📺 프로젝트 실행화면

|Diary 생성|Diary 공유 삭제(detail)|Diary 공유 삭제(cell swipe)|
|---------|---------|----|
|![](https://i.imgur.com/VEdNmAn.gif)|![](https://i.imgur.com/smWDvAH.gif)|![](https://i.imgur.com/ZQWRW3F.gif)|

## 👀 PR
- [STEP1](https://github.com/yagom-academy/ios-diary/pull/1)
- [STEP2](https://github.com/yagom-academy/ios-diary/pull/11)
- [STEP3]()

## 🛠 개발환경 및 라이브러리
- [![swift](https://img.shields.io/badge/swift-5.0-orange)]()
- [![xcode](https://img.shields.io/badge/Xcode-13.0-blue)]()
- [![iOS](https://img.shields.io/badge/iOS-15.0-red)]()

## 🔑 키워드

`SwiftLint`
`UITableViewDiffableDataSource`
`Date Formatter`
`keyboardLayoutGuide`
`View Drawing Cycle`
`CoreData`
`LightWeight Migration`
`async await`
`Task`
`Actor`
`의존성 주입/ 의존성 역전`
`CLLocationManager`
`Coordinator 패턴`

## ✨ 구현내용

- SwiftLint 적용
- UITableViewDiffableDataSource를 활용한 TableView 구현
- DateFormatter를 활용하여 사용자의 지역 포멧에 맞게 작성일자 표현
- KeyboardLayoutGuide를 활용하여 TextView가 키보드에 의해 가려지지 않도록 구현
- CoreData를 활용한 Local DB 구현
- CoreData lightweight migration으로 변경된 CoreData 모델 적용
- async await, OpenWeatherAPI을 활용한 네트워크 비동기 통신 구현
- CLLocationManager를 활용해서 위치권한 요청 & 현재위치 획득
- Coordinator Pattern으로 ViewController 화면 전환 관리

## STEP 1️⃣ 고민한점: 리스트 및 일기장 영역 화면 UI구현

<details>
    <summary><font size= "4em"><b>1. TextView가 중간부터 시작하는 문제</b></font></summary>
<div markdown="1">

<br>![](https://i.imgur.com/7WLjXsL.gif)

TextView가 길어지면, 위가 살짝 잘린채로 시작하는 문제가 있었습니다. 처음에는 TextView의 상단이 navigationBar에 가려진건가 싶어서 textView의 top을 view의 safeArea.top에 맞춰봤지만, 문제가 해결되지 않았습니다.

처음에는 저희가 뭔가 잘못한 줄 알았는데 찾아보니 textView는 원래 그렇다고 하더군요.
viewDidLoad에서 diaryTextView.contentOffset = .zero로 설정해서 해결했습니다

</div>
</details>
</br>
<details>
    <summary><font size= "4em"><b>2. TextView가 키보드에 가려지는 문제</b></font></summary>
<div markdown="1">

<br>원래 전통적으로 사용하던 KeyboardNotification을 사용하여 해결하려 했으나, iOS15 부터 사용가능한 [KeyboardLayoutGuide](https://developer.apple.com/documentation/uikit/uiview/3752221-keyboardlayoutguide)를 사용해 봤습니다.
    
```swift
private func layout() {
    NSLayoutConstraint.activate([
        diaryTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        diaryTextView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
        diaryTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
        diaryTextView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
}
```

Project의 iOS deployment target이 15.2로 설정되어 있어 위의 방식을 사용해보고자 하였고,
이 과정에서 Target의 deployment 버전을 14에서 15로 변경하였습니다.

</div>
</details>

</br>

<details>
    <summary><font size= "4em"><b>3. 파일 그룹핑 방식</b></font></summary>
<div markdown="1">

뷰 컨트롤러가 많아질 것을 고려하여, 가독성을 위해 한 화면(Scene)을 기준으로 그룹을 나눠보았습니다.
    
---
**PR후 개선사항**
    
> 도메인 주도 설계 방식으로 파일을 구성하면 좋습니다. 메인이라는 큰 틀을 두고 아래의 자세한 도메인으로 구성하는 것을 추천합니다. 큰 도메인 -> 중간 도메인 -> 자세한 도메인 이런식으로 구성하는 형태로 구성하는 것을 추천드려요. 

다음과 같은 리뷰를 받아 도메인 기준으로 파일을 그룹화 하였습니다.
<img src="https://i.imgur.com/6KGzAeT.png" width="400" height="400"/>


</div>
</details>

## STEP 2️⃣ 고민한점: 코어데이터 DB 구현

<details>
    <summary><font size= "4em"><b>1. CoreData 모델 생성과 CoreData CRUD</b></font></summary>
<div markdown="1">


<br>Diary CoreData 모델 생성의 경우 DiaryEntity의 class Codegen을 Manual/None으로 만든 후, CoreDataProperties.swift 에서 직접 옵셔널을 제거해 주었습니다.
```swift
// ( ? 삭제)
@NSManaged public var body: String
@NSManaged public var createdDate: Date
@NSManaged public var id: String
@NSManaged public var title: String
```
DiaryEntity의 attribute의 optional속성은 swift언어에서의 optional을 의미하는 것이 아닌, database의 not null, 즉 table 생성 시 반드시 넣어서 만들어야 하는 값임을 확인했습니다.
    
PersistentManager에서 CRUD 수행
재사용성을 위해 초기화할때 특정 coreData ModelName을 받게 했습니다.

이 과정에서 Diary 데이터에 대한 CRUD는
PersistentManager 를 extension 하여 구분을 해주었습니다.
    
    ---
**PR 후 개선사항**
    
    기존 PersistentManager의 경우, 사용하는 곳에서 직접 초기화 해서 사용했습니다.
    그런데 CoreData는 ThreadSafe하지 않아서, 이런식의 사용은 PersistentManager를 어디서나 만들 수 있기 때문에 멀티 스레드 환경에서 문제가 될 수 있다는걸 배웠습니다. 싱글톤 패턴을 사용할 수도 있지만, 해당 방식은 지양하고 SceneDelegate에서 생성하여 DiaryTableViewController에 주입했습니다.

</div>
</details>
</br>

<details>
    <summary><font size= "4em"><b>2. 일기 자동저장 구현</b></font></summary>
<div markdown="1">

<br>프로젝트 요구사항

- 사용자가 입력을 멈추는 경우(키보드가 사라지는 경우)

    UITextView의 Delegate 매서드인 textViewDidEndEditing()에서 updateDiary() 매서드 호출합니다

- 앱이 백그라운드로 진입하는 경우

    SceneDelegate의 sceneDidEnterBackground() 에서 Notification을 Post 합니다.
DiaryDetailViewController에 해당 Notification에 대한 옵져버를 등록하고             updateDiary()를 호출합니다.

- 이전 화면(리스트 화면)으로 이동하는 경우

    이 경우에 textViewDidEndEditing()에서 updateDiary() 매서드 호출되어 따로 처리하지 않았습니다.
    
---
**PR후 개선사항**
    
NotificationName을 "saveDiary"와 같이 하는건 좋지 않다. 이름으로도 의존성이 생길수가 있기때문
"background" 로 변경해 주었습니다

</div>
</details>
</br>

<details>
    <summary><font size= "4em"><b>3. Builder pattern을 적용한 AlertBuilder, ContextualActionBuilder </b></font></summary>
<div markdown="1">

<br>앱에서 Alert을 띄우는 일이 잦아서, 재사용성을 높이고 편하게 사용하기 위해서 고민했습니다.
이전 프로젝트에선 Model, BuilderProtocol, Builder, Director가 전부 있게 구현을 해봤는데, 굳이 그렇게 까지 해야 하나? 라는 생각이 들었습니다.

특히 setTitle(), setAction(), setStyle() 이런식으로 매서드를 하나하나 만들다보니 개발공수가 너무 많이 든다고 생각해서 Protocol과 Director를 삭제하고, title, action, style 이런 개별 단위가 아닌 model 단위로 만들도록 바꿔보았습니다.

**AlertBuilder**

```swift
func addAction(title: String, style: UIAlertAction.Style, action: (() -> Void)? = nil) -> Self {
    actions.append(AlertAction(title: title, style: style, completionHandler: action))
    return self
}
```

**ContextualActionBuilder**

```swift
func addAction(
    title: String? = nil,
    backgroundColor: UIColor? = nil,
    image: UIImage? = nil,
    style: UIContextualAction.Style,
    action: (() -> Void)?
) -> Self {
    actions.append(
        ContextualAction(
            title: title,
            backgroundColor: backgroundColor,
            image: image,
            style: style,
            completionHandler: action
        )
    )

    return self
}
```

</div>
</details>
</br>

<details>
    <summary><font size= "4em"><b>4. TableView DataSource의 분리 </b></font></summary>
<div markdown="1">

<br>`UITableViewDiffableDataSource`를 상속받은 `DiaryTableViewDataSource`를 만들어서 TableViewController와 그 DataSource를 분리하려고 시도했습니다.

VC는 dataSource를 소유하고 있고, 모든 data관련 동작은 단순히 dataSource의 매서드를 호출합니다

ex)

private var dataSource: DiaryTableViewDataSource?

// CRUD
dataSource?.create()
dataSource?.read()
dataSource?.delete(diary: diary)
dataSource?.update(diary: diary)
DataSource는 PersistentManager를 소유하고있고, in-memory Data CRUD, CoreData CRUD를 수행합니다
    

---
**PR후 개선사항**
    
MVC에서 DataSource역시 View의 관점으로 바라봐야한다.
그런의미에서는 View에서 CRUD 로직을 수행하는건 적절하지 않음.
해당 객체를 삭제하고 ViewController로 옮겨주었습니다.

</div>
</details>
</br>


## STEP 3️⃣ 고민한점: 날씨 API를 통한 날씨 기록 및 표시

<details>
    <summary><font size= "4em"><b>1. 위치 정보를 받아오는데 시간이 너무 오래걸리는 문제 </b></font></summary>
<div markdown="1">
<br>
    
requestLocation함수로 위치 정보를 요청시, 시간이 너무 오래걸리는 이슈가 있었습니다. 다음과 같이 정확도를 낮춰서 해결했습니다

```swift
locationManager.desiredAccuracy = kCLLocationAccuracyReduced
```
</div>
</details>
</br>


<details>
    <summary><font size= "4em"><b>2. 위치 정보 제공을 거절하는 경우 처리 </b></font></summary>
<div markdown="1">
<br>
     사용자가 위치권한을 주지 않아도, 즉 위치정보를 얻을 수 없어서 아래 매서드가 호출되도

```swift
locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
```

날씨 icon을 제외한 일기 자체는 제대로 만들 수 있게 구현했습니다

</div>
</details>
</br>

<details>
    <summary><font size= "4em"><b>3. async await 활용 </b></font></summary>
<div markdown="1">
    
<br>기존 GCD 방식이 아닌, swift 5.5에서 새로 나온 async await을 활용해봤습니다.
특히 네트워크 방식에서 @escaping completionHandler를 쓰지 않아서 훨씬 직관적인 코드를 작성할 수 있었습니다.
    
또 UI작업같은 경우에는 무조건 MainThread에서 작업해야했습니다.
기존에는 DispatchQueue.main.async로 감싸줘야 했는데, 새로운 Task 기반의 방식에서는 멀티스레딩 환경에서 안전한 Actor라는 개념이 있고, 그중에서도 mainActor는 항상 mainThread에서 동작됨을 보장하기 때문에 별도의 코드없이 바로 작성을 할 수 있었습니다.

</div>
</details>
</br>

<details>
    <summary><font size= "4em"><b>4. Coordinator 패턴 적용 </b></font></summary>
<div markdown="1">

<br>
    화면전환의 역할을 ViewController가 가지게 되어 발생하는 ViewController간의 의존성을 없애주기 위해 Coordinator패턴을 적용했습니다. 

하나의 Coordinator에서 모든 VC에 대한 화면전환 역할을 담당하도록 하면, 추후 node가 증가하였을때 코드가 길어져 가독성이 안좋아질 것을 고려해 각 ViewController마다 Coordinator를 하나씩 두었습니다.

각 Coordinator는 ViewController를 약하게 참조하고, ViewController는 Coordinator를 참조하고 있습니다. 그리하여 ViewController가 pop되어서 deinit이 될때, Coordinator 또한 메모리에서 해제 될 수 있도록 하였습니다.
    
</div>
</details>
</br>

<details>
    <summary><font size= "4em"><b>5. 네트워크 작업 취소 </b></font></summary>
<div markdown="1">
    
<br>

icon의 URLString을 가지고 있다가 cell이 tableView에 보여지는 시점에 icon을 가져오기 위한 네트워크 통신을 시작하기때문에, cell이 재사용됬을때 문제가 생길수 있습니다.
NetworkManager의 request메소드의 리턴타입인 `Task<UIImage, Error>`를 각 Cell에 저장해놨다가, Cell이 재사용되는 시점인 prepareForReuse에서 Task를 취소하는 식으로 구현했습니다.

</div>
</details>
</br>

<details>
    <summary><font size= "4em"><b>6. DataBase 추상화 </b></font></summary>
<div markdown="1">
    
기존에는 첫번째 VC에 CoreData를 관리하는 PersistentManager를 주입했습니다. 그래서 VC가 PersistentManager를 의존하고 있었습니다.
    
더 재사용성이 높은 객체를 만들기 위해서 DatabaseManagable 라는 프로토콜로 추상화한후 VC가 DatabaseManageable를 의존하게 해서 의존성을 역전시켜 주었습니다.
    
<br>

</div>
</details>
</br>

