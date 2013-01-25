function purchaseController($scope) {
  $scope.phones = [
    {"name": "Nexus S",
     "snippet": "Fast just got faster with Nexus S."},
    {"name": "Motorola XOOM™ with Wi-Fi",
     "snippet": "The Next, Next Generation tablet."},
    {"name": "MOTOROLA XOOM™",
     "snippet": "The Next, Next Generation tablet."},
    {"name": "iPhone 5",
     "snippet": "Best Phone in the world hands down"}
  ];

  $scope.hello = "Hello, World!"
  $scope.test = { "title": "hello",
                  "body": "my name is sean"}
}