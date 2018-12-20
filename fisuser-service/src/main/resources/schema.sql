drop table if exists userprofile;

create table  userprofile (
  id integer primary key,
  firstName varchar(50),
  lastName varchar(50),
  email    varchar(50),
  phone varchar(10),
  addr varchar(50),
  state varchar(50),
  username varchar(50)
);

INSERT INTO userprofile (id, firstName, lastName,email,phone,addr,state,username) VALUES (11111,'Abdul', 'Hameed','abdulhameedmemon@gmail.com','6364858533','172 waltham','MA','ahameed');
INSERT INTO userprofile (id, firstName, lastName,email,phone,addr,state,username) VALUES (22222,'test2', 'test2','ahameed@redhat.com','7264947276','43 SLIVER EAGLE ST, RIVER','MA','username2');
INSERT INTO userprofile (id, firstName, lastName,email,phone,addr,state,username) VALUES (33333,'test3', 'username3','abdulhameed.memon@yahoo.com','4274558382','67 RED LION ST ROCK','NY','username3');
INSERT INTO userprofile (id, firstName, lastName,email,phone,addr,state,username) VALUES (44444,'Kelly J', 'username4','username4@gmail.com','3530880835','8 GREEN SHARK ST, MOUNTAIN','CA','username4');





	