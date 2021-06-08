pragma solidity >=0.4.0 <0.7.0;

//Land Details
contract LandContract{
    
    struct landObject{
        
        address owner;      // legal owner of the land
        string location;    // Human readable location
        bool buildable;     // Can legally be built
        uint256 totalArea;  // Total area
        uint256 maxHeight;  // Legally height limit

    }

    struct Coordinate {
        uint256 dd;    // decimal degrees: represent the value of (degrees, mins and seconds)
    }

    struct Vertex {
        Coordinate coordLat; 
        Coordinate coordLong; 
    }
 
    //profile of a client
    struct profiles{
        uint256[] landList;   
    }
    
    address owner;
    
    // id->Land
    mapping(uint => landObject) land;
    // owner->id
    mapping(address => profiles) profile;
    // id->vertexArray
    mapping(uint256 => Vertex[]) mapVertex;   
    
    //first set the contract owner
    constructor() public{
        owner = msg.sender;
    }
    // Just the owner can register a land
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    //Registration of land details.
    function Registration(string memory _location, 
                            bool _buildable,
                            uint256 _maxHeight,
                            address _ownerAddress, 
                            uint256[] memory vertexX, 
                            uint256[] memory vertexY,
                            uint256 _totalArea, 
                            uint256 id
        ) public returns(bool) {
        
        // new land requirements 
        require(owner == msg.sender
                && vertexX.length == vertexY.length
                && (vertexX.length >= 3 && vertexY.length >= 3) );
        
        // new land
        land[id].location = _location;
        land[id].buildable = _buildable;
        land[id].maxHeight = _maxHeight;
        land[id].owner = _ownerAddress;
        land[id].totalArea = _totalArea;
    
        uint256 i=0;
        // Add the vertex to the map based on id
        for(i; i<vertexX.length; i++) {
            mapVertex[id].push(Vertex(Coordinate(vertexX[i]),Coordinate(vertexY[i])));
        }
        
        profile[_ownerAddress].landList.push(id);
        
        return true;
        
    }
    
    //to view details of land for the owner
    function getLandById(uint256 id) public view returns(string memory,bool,uint256,uint256){
        return(land[id].location,
                land[id].buildable,
                land[id].totalArea,
                land[id].maxHeight);
    }
    
    function isBuildable(uint256 id) public view returns(bool){
        return land[id].buildable;
    }
    
     function maxHeight(uint256 id) public view returns(uint256){
        return land[id].maxHeight;
    }

    //get lands from a given address
    function viewLands(address _owner) public view returns(uint256[] memory){
        return (profile[_owner].landList);
    }
    
    //to view details of land
    function getLandVertexById(uint256 id) public view returns(uint256[] memory,uint256[] memory){
        
        uint256[] memory vertexX = new uint256[](mapVertex[id].length);
        uint256[] memory vertexY = new uint256[](mapVertex[id].length);
        
        uint256 i;
        for(i = 0; i<mapVertex[id].length; i++) {
            vertexX[i] = mapVertex[id][i].coordLat.dd;
            vertexY[i] = mapVertex[id][i].coordLong.dd;
        }
        
        return (vertexX,vertexY);
    }
    
    // Check if a given id land is already owned
    function landIsRegistered(uint256 id) public view returns(bool){
        // if the land is not yet registered its value is: 0x000... or address(0)
        return land[id].owner != address(0);
    }
   
    function getLandNumVertex(uint256 id) public view returns(uint256){
        
        return mapVertex[id].length;
    }
    
    function getLandArea(uint256 id) public view returns(uint256){
        
        uint256 numVertex = getLandNumVertex(id);
        
        uint256[] memory vertexX = new uint256[](numVertex);
        uint256[] memory vertexY = new uint256[](numVertex);
        
        (vertexX,vertexY) = getLandVertexById(id);
        
        uint256 area = calcAreaFromVertex(vertexX,vertexY);
        
        return area;
    }
    
    function calcAreaFromVertex(uint256[] memory _vertexX, 
                                uint256[] memory _vertexY) public pure returns(uint256){
        
        require(_vertexX.length == _vertexY.length
                && (_vertexX.length >= 3 && _vertexY.length >= 3) ); 
      
        uint256 area = 0;
        uint256 i;
        for(i = 0; i<_vertexX.length-1; i++) {
            area = area + (_vertexX[i]*_vertexY[i+1] - _vertexX[i+1]*_vertexY[i]);
        }
        // Final vertex with the first one
        area = area + (_vertexX[_vertexX.length]*_vertexY[0] - _vertexX[0]*_vertexY[_vertexY.length]);        
        
        return abs(area)/2;
    }
    
    function abs(uint256 x) private pure returns (uint256) {
        return x >= 0 ? x : -x;
    }
    
    
    function landContainsVertex(uint256[] memory _vertexX, 
                                uint256[] memory _vertexY, 
                                uint256 x, 
                                uint256 y) public pure returns(bool){
                                    
        /*
        Point Inclusion in Polygon
        source: https://wrf.ecse.rpi.edu/Research/Short_Notes/pnpoly.html
        by W. Randolph Franklin.
        
        The C code:
        int pnpoly(int nvert, float *vertx, float *verty, float testx, float testy)
        {
          int i, j, c = 0;
          for (i = 0, j = nvert-1; i < nvert; j = i++) {
            if ( ((verty[i]>testy) != (verty[j]>testy)) &&
        	 (testx < (vertx[j]-vertx[i]) * (testy-verty[i]) / (verty[j]-verty[i]) + vertx[i]) )
               c = !c;
          }
          return c;
        }
        */
        
        uint256 i;
        uint256 j = 0;
        bool contains = false;
        for(i = 0; i<_vertexX.length-1; j= i++) {
            if ((_vertexY[i] > y) != (_vertexY[j] > y) 
                && (x < ((_vertexX[j]-_vertexX[i]) * (y-_vertexY[i]) / (_vertexY[j]-_vertexY[i]) + _vertexX[i] ))){
                    contains = !contains;
                }
        }
        
        return contains;
    }
    
}
