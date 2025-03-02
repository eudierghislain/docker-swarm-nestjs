import {
  Controller,
  Get,
  Post,
  Body,
  Put,
  Param,
  Delete,
  ParseIntPipe,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { User as UserModel } from '@prisma/client';

@Controller('users')
export class UsersController {

  constructor(
    private readonly usersService: UsersService
  ) { }

  @Get()
  async getUsers(): Promise<UserModel[]> {
    return this.usersService.getUsers({});
  }

  @Get(':id')
  async getUserById(@Param('id', ParseIntPipe) id: number): Promise<UserModel> {
    return this.usersService.getUser({ id });
  }

  @Post()
  async createUser(
    @Body() userData: { name?: string; email: string },
  ): Promise<UserModel> {
    return this.usersService.createUser(userData);
  }

  @Put(':id')
  async updateUser(
    @Param('id', ParseIntPipe) id: number,
    @Body() userData: { name?: string; email?: string },
  ): Promise<UserModel> {
    return this.usersService.updateUser({
      where: { id },
      data: userData,
    });
  }

  @Delete(':id')
  async deleteUser(@Param('id', ParseIntPipe) id: number): Promise<UserModel> {
    return this.usersService.deleteUser({ id });
  }
}