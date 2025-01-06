let
  xsvr1 = "ssh-ed25519 placeholder";
  users = [ thomas-local ];
in
{
  "placeholder".publicKeys = users ++ [ xsvr1 ];

}
