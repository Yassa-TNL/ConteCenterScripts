filename=r"/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/777/777_DoorsTask_20-01_20190817.txt"

def process_block(subject, block, jitter):
	result = []
	for row in block:
		rowwithoutspace=row.replace(" ", "")
		result.append('{}\t{}\t{}'.format(subject,jitter,rowwithoutspace))
	return result


with open("/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-Two-UCI/777/777_DoorsTask_20-01_20190817.txt") as f:	
	data = f.readlines()
	Jitter1 = data[1][35]
	Jitter2 = data[1][52]
	Jitter3 = data[1][69]
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
	maxtrail = alltrails.index('End Experiment\t\n')
	del alltrails[maxtrail]
	block1 = alltrails[header1:header2]
	block2 = alltrails[header2:header3]
	block3 = alltrails[header3:maxtrail]
	num1=header2-header1
	num2=header3-header2
	num3=maxtrails-header3

	results1 = process_block(subject, block1, Jitter1)
	results2 = process_block(subject, block2, num2, Jitter2)
	results3 = process_block(subject, block3, num3, Jitter3)

	

	for y in range(1, 4, 1):
		'results{}'.format(y)


	results2 = []
	for x in range(NUM2):
		row2=block2[x]
		rowwithoutspaces2=row2.replace(" ", "")
		results2.append('{}\t{}\t{}'.format(subject,Jitter2,rowwithoutspaces2))


','.join(x)

	results3 = []
	NUM3=maxtrails-header3
	for x in range(NUM3):
		row3=block3[x]
		rowwithoutspaces3=row3.replace(" ", "")
		results3.append('{}\t{}\t{}'.format(subject,ThirdJitter,rowwithoutspaces3))
	




test.replace(" ", "")












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
