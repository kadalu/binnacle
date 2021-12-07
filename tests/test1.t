TEST "echo Hello"
EXIT_ON_NOT_OK true do
  TEST "sleep 2"
end
EXIT_ON_NOT_OK true do
  TEST "echo Hello before"
  TEST "ls /non/existing"
  TEST "echo Hello again"
end
