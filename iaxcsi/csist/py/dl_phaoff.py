#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import torch
from torch import nn
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms
import torch.nn.functional as f

import numpy as np


class PODataset(Dataset):
    def __init__(self, paths, targets=[0]):
        super(PODataset, self).__init__()

        self.ncol = 50
        self.phaoffs = np.array([])
        self.targets = np.array([])
        for i in range(len(paths)):
            phaoffs = self.read_phaoffs(paths[i])
            self.phaoffs = np.append(self.phaoffs, phaoffs)
            sz = int(phaoffs.shape[0]/self.ncol)
            self.targets = np.append(self.targets, np.ones(sz)*targets[i])
            print(self.phaoffs.shape, self.targets.shape)

        self.phaoffs = np.reshape(self.phaoffs, [-1,self.ncol])
        print(self.phaoffs.shape, self.targets.shape)

    def read_phaoffs(self, path):
        phaoffs = np.array([])
        with open(path, 'rb') as f:
            while True:
                try:
                    phaoff = np.load(f)
                except ValueError:
                    break
                phaoffs = np.append(phaoffs, phaoff)
        return phaoffs

    def __len__(self):
        return len(self.phaoffs)

    def __getitem__(self, index):
        x = torch.tensor(self.phaoffs[index], dtype=torch.float)
        y = torch.tensor(self.targets[index], dtype=torch.float)
        y = torch.tensor([1.0,0])
        if self.targets[index] == 1:
            y = torch.tensor([0,1.0])
        return x, y


class MPhaoff(nn.Module):
    def __init__(self):
        super(MPhaoff, self).__init__()
        self.model = nn.Sequential(
            nn.Linear(50, 20),
            nn.Linear(20, 10),
            nn.Linear(10, 2),
            #nn.Flatten(0),
        )

    def forward(self, x):
        return self.model(x)


mphaoff = MPhaoff()
loss = nn.CrossEntropyLoss() 
loss = nn.L1Loss()
loss = nn.MSELoss()
optim = torch.optim.SGD(mphaoff.parameters(), lr=0.01)

#train_dataset = PODataset(['./phaoffs68.npy','./phaoffs-246.npy'], [0.68,-2.46])
train_dataset = PODataset(['./phaoffs68.npy','./phaoffs-246.npy'], [0,1])
phaoff_loader = DataLoader(dataset=train_dataset, batch_size=20, shuffle=True, num_workers=0, drop_last=True)
mphaoff.train()
for epoch in range(20):
    sum_loss = 0
    for (dat,target) in phaoff_loader:
        output = mphaoff(dat)
        #print(dat.shape, output.shape, target.shape)
        #print(target)
        #input('a')
        res_loss = loss(output, target)
        optim.zero_grad()
        res_loss.backward()
        optim.step()
        sum_loss = sum_loss + res_loss.item()
    print('* epoch {}, loss {}'.format(epoch, sum_loss))


test_dataset = PODataset(['./test.npy'])
test_loader = DataLoader(dataset=test_dataset, batch_size=1, shuffle=True, num_workers=0, drop_last=True)
mphaoff.eval()
n = 0
phaoff_labels = [0.68, -2.46]
for (dat,target) in test_loader:
    n = n + 1
    output = mphaoff(dat)
    _, pred = torch.max(output, dim=1)
    print(n, torch.mean(dat), target, output)
    print('pred {}'.format(phaoff_labels[pred]))
    input('-\n')
# test 2.6 to 0.68, should -2.46


'''
class PODatasetTest(Dataset):
    def __init__(self):
        super(PODatasetTest, self).__init__()
        #outputs = torch.tensor(range(500), dtype=torch.float)
        self.outputs = torch.arange(0,500, dtype=torch.float)
        self.targets = torch.arange(0,500, dtype=torch.float)

    def __len__(self):
        return len(self.outputs)

    def __getitem__(self, index):
        cell = torch.arange(0,50)/1e5
        t0 = torch.tensor(0, dtype=torch.float)
        return self.outputs[index]*cell, self.targets[index]
        return self.outputs[index]*cell, t0
'''




