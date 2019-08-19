filename=r"/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/777/777_DoorsTask_20-01_20190817.txt"



with open("/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/777/777_DoorsTask_20-01_20190817.txt") as f:	
	data = f.readlines()
	FirstJitter = data[1][35]
	SecondJitter = data[1][52]
	ThirdJitter = data[1][69]
	subject = data[2]
	subject = subject.replace('Subject ID: ', '')
	subject = subject.replace('\n', '')
	alltrails = filter(lambda x:'\t' in x, data)
	header1 = alltrails.index('Trial\tDoorsAppear\tResp\tRespTime\t\tFeedback\tFeedbackTime\tJitter\n')
	del alltrails[header1]
	header2 = alltrails.index('Trial\tDoorsAppear\tResp\tRespTime\t\tFeedback\tFeedbackTime\tJitter\n')
	del alltrails[header2]
	header3 = alltrails.index('Trial\tDoorsAppear\tResp\tRespTime\t\tFeedback\tFeedbackTime\tJitter\n')
	del alltrails[header3]
	maxtrails = alltrails.index('End Experiment\t\n')
	del alltrails[maxtrails]
	block1 = alltrails[header1:header2]
	block2 = alltrails[header2:header3]
	block3 = alltrails[header3:maxtrails]
	NUM1=header2-header1
	results1 = []
	for x in range(NUM1):
		results1.append('{}\t{}\t{}'.format(subject,FirstJitter,block1[x]))
	NUM2=header3-header2
	results2 = []
	for x in range(NUM2):
		results2.append('{}\t{}\t{}'.format(subject,SecondJitter,block3[x]))
	NUM3=maxtrails-header3
	results3 = []
	for x in range(NUM3):
		results3.append('{}\t{}\t{}'.format(subject,ThirdJitter,block2[x]))
	














 max(enumerate(alltrails), key=(lambda x: x[1]))





	alltrails.split('Trial\tDoorsAppear\tResp\tRespTime\t\tFeedback\tFeedbackTime\tJitter\n', 3)


names = ['aet2000','ppt2000', 'aet2001', 'ppt2001']
>>> 



	line = re.findall(r'Doors-', line)[1]
	



	data.split('Doors-')[1]  







	a,b,c = x.split(“Doors”)






	print(data[2])




	f_contents = f.readlines()
	print(f_contents)
	





for line in file:
print line,

	print file.readlines() 




    stripped = (line.strip() for line in file)

lines = readin.readlines()
out1.write(''.join(lines[5:67]))
out2.write(''.join(lines[89:111]))
