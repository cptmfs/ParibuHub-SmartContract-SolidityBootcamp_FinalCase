// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract RentalManagement {
    struct User {
        string name;
        bool isTenant;
        bool isLandlord;
    }

    // Mülk bilgileri
    struct Property {
        int Id;
        string name;
        string description;
        address owner;
        bool isRentable; 
        address tenant;

    }
    //Kira bilgileri
    struct Lease {
        address tenant;
        int propertyId; 
        uint256 startDate;
        uint256 endDate;
    }
    // Şikayet bilgileri
    struct Complaint {
        address user;
        int propertyId; // Şikayet edilen mülkün ID'si
        string description;
        string response; // Mülk sahibinin yanıtı
    }
    // Erken fesih bilgileri
     struct EarlyTermination {
        address tenant;
        int propertyId; // Sözleşme hangi mülke ait?
        uint256 requestTime;
        bool isApproved;
    }

    // Kullanıcıları adresleriyle eşleyen  mapping
    mapping(address => User) public users;

    // Mülkleri Id'lere göre eşleyen  mapping
    mapping(int => Property) public properties;

    // Kiraları temsil eden  dizi
    Lease[] public leases;

    // Şikayetleri temsil eden  dizi
    Complaint[] public complaints;

    // Erken tarihli sözleşme feshi tutan dizi
    EarlyTermination[] public earlyTerminationRequests;

    // Kayıtlı kullanıcıları listelemek için kullanılan  adres dizisi
    address[] public userList;

    // Her mülkün Id'sini takip etmek için kullanılan  sayaç
    int public propertyIdCounter;

    // Her rol için kullanıcı sayılarını tutan değişkenler
    uint256 public tenantCount;
    uint256 public landlordCount;

    constructor() {
        propertyIdCounter = 1; // Property Id'si 1'den başlayacak
    }

    // Kayıtlı kullanıcıları listelemek için kullanılan fonksiyon
    function listUsers() public view returns (uint256 tenantCount, uint256 landlordCount) {
        for (uint256 i = 0; i < userList.length; i++) {
            if (users[userList[i]].isTenant) {
                tenantCount++;
            }
            if (users[userList[i]].isLandlord) {
                landlordCount++;
            }
        }
    }

    // Kiralık mülkleri listelemek için kullanılan fonksiyon
    function listRentedProperties() public view returns (address[] memory) {
        address[] memory rentedPropertyList = new address[](leases.length);
        for (uint256 i = 0; i < leases.length; i++) {
            rentedPropertyList[i] = properties[leases[i].propertyId].owner;
        }
        return rentedPropertyList;
    }

    // Yeni kullanıcı oluşturma işlemi
    function createUser(string memory name, bool _isTenant, bool _isLandlord) public {
        require(!users[msg.sender].isTenant && !users[msg.sender].isLandlord, "User already exists");
        users[msg.sender] = User(name, _isTenant, _isLandlord);
        userList.push(msg.sender); // Yeni kullanıcıyı kullanıcı listesine ekleyin
    }

    // Yeni mülk oluşturma işlemi  // Eğer kullanıcı landrod ise yapabilir.
    function createProperty(string memory name, string memory description) public {
        require(users[msg.sender].isLandlord, "Only landlords can create properties");
        properties[propertyIdCounter] = Property(propertyIdCounter, name, description, msg.sender,true,address(0));
        
        propertyIdCounter++; // Her mülk oluşturulduğunda Id'yi arttır
    }

    // Yeni kira sözleşmesi oluşturma işlemi
    function createLease(address tenant, int propertyId, uint256 startDate, uint256 endDate) public {
        require(users[tenant].isTenant && properties[propertyId].owner == msg.sender, "Invalid tenant or property");
        require(properties[propertyId].isRentable, "Property is not rentable");
        leases.push(Lease(tenant, propertyId, startDate, endDate));
        properties[propertyId].isRentable = false; // Kiralandığında mülkün kiralanabilir durumunu false yap
    }

        // Yeni şikayet oluşturma işlemi
    function createComplaint(int propertyId, string memory description) public {
        require(users[msg.sender].isTenant, "Only tenants can create complaints");
        require(properties[propertyId].tenant == msg.sender, "You can only complain about a rented property");
        complaints.push(Complaint(msg.sender, propertyId, description, ""));
    }

    // Mülk sahipleri için şikayetlere yanıt verme işlemi
    function respondToComplaint(uint256 complaintIndex, string memory response) public {
        require(users[msg.sender].isLandlord, "Only landlords can respond to complaints");
        require(complaintIndex < complaints.length, "Invalid complaint index");
        Complaint storage complaint = complaints[complaintIndex];
        require(properties[complaint.propertyId].owner == msg.sender, "You are not the owner of the property related to this complaint");
        complaint.response = response;
    }

     // Kiracıların kendi şikayetlerini görme işlemi
    function getTenantComplaints() public view returns (int[] memory, string[] memory, string[] memory, string[] memory) {
        int[] memory propertyIds = new int[](complaints.length);
        string[] memory descriptions = new string[](complaints.length);
        string[] memory responses = new string[](complaints.length);
        string[] memory responseOwners = new string[](complaints.length);

        for (uint256 i = 0; i < complaints.length; i++) {
            Complaint memory complaint = complaints[i];
            if (complaint.user == msg.sender) {
                propertyIds[i] = complaint.propertyId;
                descriptions[i] = complaint.description;
                responses[i] = complaint.response;
                responseOwners[i] = properties[complaint.propertyId].owner == address(0) ? "" : users[properties[complaint.propertyId].owner].name;
            }
        }

        return (propertyIds, descriptions, responses, responseOwners);
    }

    // Mülk sahiplerinin mülklerine gelen şikayetleri görme işlemi
    function getLandlordComplaints() public view returns (int[] memory, string[] memory, string[] memory) {
        int[] memory propertyIds = new int[](complaints.length);
        string[] memory descriptions = new string[](complaints.length);
        string[] memory responses = new string[](complaints.length);

        for (uint256 i = 0; i < complaints.length; i++) {
            Complaint memory complaint = complaints[i];
            if (properties[complaint.propertyId].owner == msg.sender) {
                propertyIds[i] = complaint.propertyId;
                descriptions[i] = complaint.description;
                responses[i] = complaint.response;
            }
        }

        return (propertyIds, descriptions, responses);
    }

    // Mülkleri Listele
    function listProperties(uint id) public view returns (int[] memory, string[] memory, string[] memory, address[] memory) {
        int[] memory propertyIds = new int[](userList.length);
        string[] memory propertyNames = new string[](userList.length);
        string[] memory propertyDescriptions = new string[](userList.length);
        address[] memory propertyOwners = new address[](userList.length);

        for (uint256 i = 0; i < userList.length; i++) {
            int propertyId = int(i + 1); // Property Id'si, dizin + 1 olarak kabul ediliyor
            Property memory property = properties[propertyId];
            propertyIds[i] = propertyId;
            propertyNames[i] = property.name;
            propertyDescriptions[i] = property.description;
            propertyOwners[i] = property.owner;
        }

        return (propertyIds, propertyNames, propertyDescriptions, propertyOwners);
    }
    
    // Sözleşmeyi fesh etme işlemi
    function terminateLease(int propertyId, address tenant) public {
        require(users[msg.sender].isLandlord, "Only landlords can terminate leases");

        // İlgili mülk sahibi mi kontrol 
        require(properties[propertyId].owner == msg.sender, "You are not the owner of the property");

        // Kiracı doğrulama
        for (uint256 i = 0; i < leases.length; i++) {
            if (leases[i].propertyId == propertyId && leases[i].tenant == tenant) {
                // Sözleşmeyi sonlandırma
                leases[i].endDate = block.timestamp;
                break;
            }
        }
    }

    // Erken tarihli sözleşme sonlandırma talebi oluşturma    /// Burada sadece kiraladığı mülkün isteğini gönderebileceğini kontrol et.!!!
    function requestEarlyTermination(int propertyId) public {
        require(users[msg.sender].isTenant, "Only tenants can request early termination");
           
        bool hasLease = false;
        // Kiracının sözleşmesi var mı ve mülk sahibi mi kontrol
        for (uint256 i = 0; i < leases.length; i++) {
            if (leases[i].propertyId == propertyId && leases[i].tenant == msg.sender) {
                hasLease = true;
                break;
            }
        }

        require(hasLease, "You do not have a lease for this property");
        earlyTerminationRequests.push(EarlyTermination(msg.sender, propertyId, block.timestamp, false));
    }

    // Erken tarihli sözleşme sonlandırma talebini onaylama
    function approveEarlyTermination(uint256 requestIndex) public {
        require(users[msg.sender].isLandlord, "Only landlords can approve early termination");
        require(requestIndex < earlyTerminationRequests.length, "Invalid request index");

        EarlyTermination storage request = earlyTerminationRequests[requestIndex];
        require(properties[request.propertyId].owner == msg.sender, "You are not the owner of the property");

        // Erken tarihli sözleşme sonlandırma işlemi.
        terminateLease(request.propertyId, request.tenant);

        // Talebi onaylandı olarak işaretleme
        request.isApproved = true;

        properties[request.propertyId].isRentable=true;
    }
}

    

