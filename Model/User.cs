using System;

namespace Model {
    public class User {
        public long Id{get;set;}
        public string Username{get; set;}
        public string Password{get;set;}

        public DateTime CreationTime {get;set;}
    }
}