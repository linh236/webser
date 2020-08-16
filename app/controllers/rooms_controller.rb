class RoomsController < ApplicationController
  before_action :set_room, only: [:show, :edit, :update, :destroy, :payroom]
  before_action  only: [:room_fast, :addcustomer, :listcustomer, :payroom, :edit, :destroy, :new] do
    check_admin_login("/houses")
  end

  FIREBASE_URL    = 'https://iotpro-58c44.firebaseio.com/'
  FIREBASE_SECRET = 'F4mMmNXp1CPYvJYX5KwtrLifqw6UvVO4fyCUKhoj'
  # GET /rooms
  # GET /rooms.json
  def index
    @rooms = Room.all
  end

  # GET /rooms/1
  # GET /rooms/1.json
  def show
  end

  # GET /rooms/new
  def new
    @room = Room.new
    @houses = House.order("id DESC")
  end

  # GET /rooms/1/edit
  def edit
    @houses = House.order("id DESC")
  end

  # POST /rooms
  # POST /rooms.json
  def create
    @room = Room.new(room_params)
    house = House.find(@room.house_id)
    name = house.name
    re_space_house_name = name.gsub(" ","")
    upercase_house_name = re_space_house_name.upcase
    if @room.save
      create_house_room_firebase(upercase_house_name, @room.name)
      flash[:notice] =  'Thêm phòng thành công.'
      redirect_to houses_path
    else
      flash[:warning] =  flash_errors(@room.errors)
      redirect_to houses_path
    end
  end

  def room_fast
    @houses = House.order("id DESC")

  end
  def roomfast
    start = params[:start]
    finsh = params[:end]
    house_id = params[:house_id]
    amount = params[:amount]
    width = params[:width]
    length = params[:length]
    description = params[:description]
    cost = params[:cost]
    house = House.find(house_id)
    name = house.name
    re_space_house_name = name.gsub(" ","")
    upercase_house_name = re_space_house_name.upcase
    for i in start.to_i..finsh.to_i
      room = Room.new(name: i, amount: amount, cost: cost, width: width, length: length, description: description, house_id: house_id)
      create_house_room_firebase(upercase_house_name, i)
      if room.save
        flash[:notice] = "Them phong moi thanh cong"
      else
        flash[:notice] = "Them phong moi that bai"
      end
    end
    redirect_to houses_path
  end

  def addcustomer
    @house = House.where(id: params[:house_id])
    @room = Room.where(id: params[:room_id])
    @services = Service.all.order("status DESC")
    if params[:information_id].present?
      @infor = Information.find(params[:information_id])
    end
  end

  def listcustomer
    @house = House.where(id: params[:house_id])
    @room = Room.where(id: params[:room_id])
    @information = Information.where(id: params[:information_id])
    @check_use_service = UseService.find_by_information_id(params[:information_id])
    if @check_use_service.nil?
      @services = Service.all.order("status DESC")
    else
      @services = Service.all.order("status DESC")
      @use_services = UseService.where(information_id: params[:information_id])
    end
    check_member = Member.find_by_information_id(params[:information_id])
    if !check_member.nil?
      @member = check_member
    end
  end

  def payroom
    paytherent = Paytherent.where(information_id: params[:information_id], status: 0)
    if paytherent.size !=0
      flash[:warning] = "Xin vui lòng trả tiền phòng trước khi trả phòng"
      redirect_to houses_path
    else
      if @room.update(information_id: "", mark: 0, oldelectric: 0, newelectric: 0, oldwater: 0, newwater: 0)
        inf = Information.find(params[:information_id])
        user = User.find_by_email(inf.email)
        if user.update(disable: 1)
          if inf.update(mark: 1)
            use_service = UseService.find_by_information_id(params[:information_id])
            UseService.delete(use_service.id)
            flash[:notice] = "Trả phòng thành công !"
            redirect_to houses_path
          end
        end
      else
        flash[:warning] = "Trả phòng thất bại !"
        redirect_to houses_path
      end
    end
  end

  def indexservice
    oldelectric = params[:oldelectric]
    newelectric = params[:newelectric]
    oldwater = params[:oldwater]
    newwater = params[:newwater]
    room = Room.find(params[:room_id])
    if room.update(oldelectric: oldelectric, newelectric: newelectric, oldwater: oldwater, newwater: newwater)
      flash[:notice] = "Cập nhật thành công"
      redirect_to "/listcustomer/#{params[:house_id]}/#{params[:room_id]}/#{params[:information_id]}"
    end
  end
  # PATCH/PUT /rooms/1
  # PATCH/PUT /rooms/1.json
  def update

    respond_to do |format|
      if @room.update(room_params)
        format.html { redirect_to houses_path, notice: 'Room was successfully updated.' }
        format.json { render :show, status: :ok, location: @room }
      else
        format.html { render :edit }
        format.json { render json: @room.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rooms/1
  # DELETE /rooms/1.json
  def destroy
    @room.destroy
    respond_to do |format|
      format.html { redirect_to houses_path, notice: 'Xóa phòng thành công' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_room
      @room = Room.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def room_params
      params.require(:room).permit(:name, :cost, :length, :width, :amount, :allow, :description, :picture, :house_id, service_id: [], )
    end

    def create_house_room_firebase house_name, room_name
      firebase = Firebase::Client.new(FIREBASE_URL, FIREBASE_SECRET)
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS0/STATUS": "OFF"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS0/TURNON": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS0/TURNOFF": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS1/STATUS": "OFF"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS1/TURNON": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS1/TURNOFF": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS2/STATUS": "OFF"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS2/TURNON": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS2/TURNOFF": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS3/STATUS": "OFF"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS3/TURNON": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS3/TURNOFF": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS5/STATUS": "OFF"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS5/TURNON": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS5/TURNOFF": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS6/STATUS": "OFF"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS6/TURNON": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS6/TURNOFF": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS7/STATUS": "OFF"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS7/TURNON": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS7/TURNOFF": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS8/STATUS": "OFF"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS8/TURNON": "13:00"})
      firebase.update(FIREBASE_URL, {"#{house_name}/Phong#{room_name}/LED_STATUS8/TURNOFF": "13:00"})
    end
end
